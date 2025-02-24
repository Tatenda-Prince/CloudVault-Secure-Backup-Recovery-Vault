import boto3
import os
import json
import logging
from datetime import datetime

# Setup logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
ec2 = boto3.client("ec2")
s3 = boto3.client("s3")
sns = boto3.client("sns")

# Environment variables
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
S3_BUCKET = os.environ.get("S3_BUCKET")

def lambda_handler(event, context):
    try:
        if not SNS_TOPIC_ARN or not S3_BUCKET:
            logger.error("Missing required environment variables: SNS_TOPIC_ARN or S3_BUCKET")
            return {"statusCode": 500, "body": "Environment variables not set properly"}

        # Fetch instances with the tag Name=Backup-Recovery-EC2
        response = ec2.describe_instances(
            Filters=[{"Name": "tag:Name", "Values": ["Backup-Prod-EC2"]}]
        )
        instances = response.get("Reservations", [])

        if not instances:
            logger.warning("No instances found with the tag 'Backup-Prod-EC2'.")
            return {"statusCode": 404, "body": "No matching instances found"}

        snapshots_created = []

        for instance in instances:
            ec2_instance = instance["Instances"][0]
            instance_id = ec2_instance["InstanceId"]

            # Fetch all attached EBS volumes
            block_devices = ec2_instance.get("BlockDeviceMappings", [])
            volume_ids = [device["Ebs"]["VolumeId"] for device in block_devices if "Ebs" in device]

            if not volume_ids:
                logger.error(f"Instance {instance_id} has no attached EBS volumes.")
                continue  # Skip instance if no volumes exist

            for volume_id in volume_ids:
                try:
                    # Create a snapshot for each volume
                    snapshot = ec2.create_snapshot(
                        VolumeId=volume_id,
                        Description=f"Automated backup of {volume_id} on {datetime.now().isoformat()}",
                    )
                    snapshot_id = snapshot["SnapshotId"]
                    logger.info(f"Snapshot {snapshot_id} created for volume {volume_id}")

                    # Save snapshot metadata to S3
                    metadata = {
                        "instance_id": instance_id,
                        "volume_id": volume_id,
                        "snapshot_id": snapshot_id,
                        "timestamp": datetime.now().isoformat(),
                    }

                    s3_key = f"backups/{snapshot_id}.json"
                    s3.put_object(Bucket=S3_BUCKET, Key=s3_key, Body=json.dumps(metadata, indent=4))
                    logger.info(f"Snapshot metadata saved to S3: {S3_BUCKET}/{s3_key}")

                    # Send SNS notification
                    sns.publish(
                        TopicArn=SNS_TOPIC_ARN,
                        Message=f"Backup completed: {snapshot_id} for instance {instance_id}, volume {volume_id}.",
                        Subject="EBS Backup Notification",
                    )
                    logger.info(f"SNS notification sent for snapshot {snapshot_id}")

                    snapshots_created.append(snapshot_id)

                except Exception as e:
                    logger.error(f"Error creating snapshot for volume {volume_id}: {str(e)}")

        if snapshots_created:
            return {"statusCode": 200, "body": f"Backup process completed. Snapshots: {snapshots_created}"}
        else:
            return {"statusCode": 500, "body": "Backup process failed. No snapshots created."}

    except Exception as e:
        logger.error(f"Error during backup: {str(e)}")
        return {"statusCode": 500, "body": f"Error: {str(e)}"}

