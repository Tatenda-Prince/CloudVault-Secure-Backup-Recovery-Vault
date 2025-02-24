import boto3
import os
import time

# AWS Clients
ec2 = boto3.client("ec2")
sns = boto3.client("sns")

# Environment Variables
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
INSTANCE_TYPE = os.environ["INSTANCE_TYPE"]
KEY_NAME = os.environ["KEY_NAME"]
SECURITY_GROUP = os.environ["SECURITY_GROUP"]
SUBNET_ID = os.environ["SUBNET_ID"]
AVAILABILITY_ZONE = os.environ.get("AVAILABILITY_ZONE", "us-east-1b")

def get_latest_snapshot(volume_id):
    """Fetch the latest snapshot for the given volume."""
    try:
        snapshots = ec2.describe_snapshots(
            Filters=[{"Name": "volume-id", "Values": [volume_id]}],
            OwnerIds=["self"]
        )["Snapshots"]

        if not snapshots:
            return None

        latest_snapshot = max(snapshots, key=lambda s: s["StartTime"])
        return latest_snapshot["SnapshotId"]

    except Exception as e:
        print(f"Error fetching snapshots: {str(e)}")
        return None

def create_volume_from_snapshot(snapshot_id):
    """Create a new EBS volume from the latest snapshot."""
    try:
        print(f"Creating volume from snapshot {snapshot_id}...")
        volume = ec2.create_volume(
            SnapshotId=snapshot_id,
            AvailabilityZone=AVAILABILITY_ZONE,
            VolumeType="gp3"
        )

        volume_id = volume["VolumeId"]
        print(f"Volume {volume_id} created. Waiting for availability...")

        waiter = ec2.get_waiter("volume_available")
        waiter.wait(VolumeIds=[volume_id])
        print(f"Volume {volume_id} is now available.")

        return volume_id

    except Exception as e:
        print(f"Error creating volume: {str(e)}")
        return None

def launch_new_instance():
    """Launch a new EC2 instance with a default root volume."""
    try:
        print("Launching new EC2 instance...")

        response = ec2.run_instances(
            ImageId="ami-05b10e08d247fb927",  # Replace with the latest AMI ID
            InstanceType=INSTANCE_TYPE,
            KeyName=KEY_NAME,
            MinCount=1,
            MaxCount=1,
            SecurityGroupIds=[SECURITY_GROUP],
            SubnetId=SUBNET_ID,
            TagSpecifications=[{"ResourceType": "instance", "Tags": [{"Key": "Name", "Value": "Recovered-EC2"}]}]
        )

        new_instance_id = response["Instances"][0]["InstanceId"]
        print(f"New instance {new_instance_id} launched. Waiting for it to be running...")

        instance_waiter = ec2.get_waiter("instance_running")
        instance_waiter.wait(InstanceIds=[new_instance_id])
        print(f"Instance {new_instance_id} is now running.")

        return new_instance_id

    except Exception as e:
        print(f"Error launching new instance: {str(e)}")
        return None

def attach_volume_to_instance(instance_id, volume_id):
    """Attach the recovered volume to the new instance without stopping it."""
    try:
        print(f"Fetching root volume of instance {instance_id}...")

        instance_info = ec2.describe_instances(InstanceIds=[instance_id])
        root_volume_id = instance_info["Reservations"][0]["Instances"][0]["BlockDeviceMappings"][0]["Ebs"]["VolumeId"]
        print(f"Root volume ID: {root_volume_id}")

        print(f"Detaching original root volume {root_volume_id} (force)...")
        ec2.detach_volume(VolumeId=root_volume_id, Force=True)
        time.sleep(10)  # Allow time for detachment

        print(f"Attaching new volume {volume_id} as root volume to instance {instance_id}...")
        ec2.attach_volume(
            VolumeId=volume_id,
            InstanceId=instance_id,
            Device="/dev/xvda"
        )

        print(f"Instance {instance_id} is now running with the recovered volume.")

    except Exception as e:
        print(f"Error attaching volume: {str(e)}")

def lambda_handler(event, context):
    """Triggered when an EC2 instance fails, automatically recovers from snapshot."""
    try:
        failed_instance_id = event["detail"]["instance-id"]
        print(f"Failed Instance ID: {failed_instance_id}")

        response = ec2.describe_instances(InstanceIds=[failed_instance_id])
        instances = response.get("Reservations", [])

        if not instances:
            print("Error: Instance details not found")
            return {"statusCode": 404, "body": "Instance not found"}

        instance_data = instances[0]["Instances"][0]
        block_device_mappings = instance_data.get("BlockDeviceMappings", [])

        if not block_device_mappings:
            print(f"Error: No block device mappings found for instance {failed_instance_id}")
            return {"statusCode": 500, "body": "No block devices found"}

        volume_id = block_device_mappings[0]["Ebs"]["VolumeId"]
        print(f"Volume ID: {volume_id}")

        latest_snapshot = get_latest_snapshot(volume_id)
        if not latest_snapshot:
            print(f"No snapshots found for instance {failed_instance_id}")
            sns.publish(
                TopicArn=SNS_TOPIC_ARN,
                Message=f"No snapshots found for instance {failed_instance_id}",
                Subject="EC2 Recovery Failed"
            )
            return {"statusCode": 500, "body": "No snapshots found"}

        print(f"Latest Snapshot ID: {latest_snapshot}")

        restored_volume_id = create_volume_from_snapshot(latest_snapshot)
        if not restored_volume_id:
            return {"statusCode": 500, "body": "Failed to create volume"}

        new_instance_id = launch_new_instance()
        if not new_instance_id:
            return {"statusCode": 500, "body": "Failed to launch new instance"}

        attach_volume_to_instance(new_instance_id, restored_volume_id)

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=f"New EC2 instance {new_instance_id} launched and restored from snapshot {latest_snapshot}",
            Subject="EC2 Recovery Notification"
        )

        return {"statusCode": 200, "body": f"New instance {new_instance_id} launched and restored"}

    except Exception as e:
        print(f"Lambda error: {str(e)}")
        return {"statusCode": 500, "body": f"Error: {str(e)}"}
