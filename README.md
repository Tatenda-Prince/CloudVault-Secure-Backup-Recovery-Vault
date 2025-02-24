# CloudVault-Secure-Backup-Recovery-Vault

"Automated Backup &amp; Recovery System"

## Technical Architecture

![image_alt]()


## Project Overview

The "Automated Secure Backup & Recovery Vault" provides a strong disaster recovery solution using AWS to automatically safeguard EC2 instances by backing them up and restoring them when they encounter failures. The project uses Terraform for infrastructure as code to enable straightforward and consistent deployment processes.

## Project Objective

To build an automated, secure, and cost-efficient EC2 backup and recovery system that:

1.Takes periodic snapshots of EC2 instances.

2.Stores backups securely in Amazon S3 Glacier.

3.Detects EC2 failures and launches a new instance.

4.Restores the latest snapshot to the new instance.

5.Notifies administrators via Amazon SNS alerts.


##  Features

1.Automated EC2 Snapshot Management – Regular snapshots of EBS volumes ensure data protection.

2.Disaster Recovery – Auto-launches a new EC2 instance and restores the latest snapshot upon failure.

3.Cost Optimization – Stores backups in Amazon S3 Glacier for long-term retention at a lower cost.

4.Terraform Infrastructure-as-Code (IaC) – Deploy AWS resources consistently and efficiently.

5.Event-Driven Architecture – Uses AWS Lambda & EventBridge to trigger backup and recovery.

6.Real-time Notifications – Sends SNS alerts for backup completion, failures, and recovery actions.

## Technology Used

1.AWS Lambda – Automates backup and recovery processes.

2.Amazon S3 Glacier – Cost-efficient storage for long-term backups.

3.Amazon SNS – Notifies administrators of backup and recovery events.

4.Amazon EventBridge – Triggers automated backups and recovery workflows.

5.AWS IAM – Secures access through fine-grained permissions.

6.Terraform – Infrastructure as Code (IaC) to manage all AWS resources.

## Use Case

This project serves as a valuable resource for organizations and their cloud engineers and DevOps teams who need to establish dependable disaster recovery procedures on AWS. The project provides automatic recovery which prevents data loss and downtime while maintaining business continuity.

## Prerequisites

1.AWS Account with necessary permissions.

2.Terraform Installed on your local machine.

3.AWS CLI Configured with required IAM roles.


## Step 1: Clone the Repository

1.1.Clone this repository to your local machine.

```language
git clone https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault.git
```

## Step 2 : Run Terraform workflow to initialize, validate, plan then apply

2.1.We are going to deploye our resources Amazon EC2 , AWS Lambda, Amazon Eventbridge, Amazon S3 Glacier, Amazon SNS , IAM and CloudWatch.

2.2.In your local terraform visual code environment terminal, to initialize the necessary providers, execute the following command in your environment terminal.

```language
terraform init
```

Upon completion of the initialization process, a successful prompt will be displayed, as shown below.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/c01f071ba93cbc72580be117fe8b399b9bd3a0d0/img/Screenshot%202025-02-24%20115309.png)

2.3.Next, let’s ensure that our code does not contain any syntax errors by running the following command —

```language
terraform validete
```
The command should generate a success message, confirming that it is valid, as demonstrated below.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/48c4e2a4db91d69233e385c82ff2a6587528b8d2/img/Screenshot%202025-02-24%20115442.png)

2.4.Let’s now execute the following command to generate a list of all the modifications that Terraform will apply. —

```language
terraform plan
```

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/c01ce7c99d9e35188854bbc84c7cebf28236d5ed/img/Screenshot%202025-02-24%20121437.png)


The list of changes that Terraform is anticipated to apply to the infrastructure resources should be displayed. The “+” sign indicates what will be added, while the “-” sign indicates what will be removed.


2.5.Now, let’s deploy this infrastructure! Execute the following command to apply the changes and deploy the resources.
Note — Make sure to type “yes” to agree to the changes after running this command

```language
terraform apply
```

Terraform will initiate the process of applying all the changes to the infrastructure. Kindly wait for a few seconds for the deployment process to complete.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/c7009adb932c34cae4ccdfe1ea6198a978725c94/img/Screenshot%202025-02-24%20122401.png)


## Success!

The process should now conclude with a message indicating “Apply complete”, stating the total number of added, modified, and destroyed resources, accompanied by several resources.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/441e21545b32cfac6c1b6f9cb11a88c4be03a6ac/img/Screenshot%202025-02-24%20122509.png)


## Step 3: Verify creation of our resources

3.1.In the AWS Management Console, head to the Amazon Lambda dashboard and verify that the two `ebs-backup-lambda` & `ebs-recovery-lambda` function were successfully created

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/436665ad8112ec7c38913416a8e6839669f07fbd/img/Screenshot%202025-02-24%20123417.png)


3.2.In the AWS Management Console, head to the Amazon S3 dashboard and verify that the tatenda-backup-recovery-vault bucket was successfully created with the Lifecycle Configuration `MoveToGlacier` Glacier storage class.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/d85babb79c51ab5c00509cd0ffaaba6af79d56f2/img/Screenshot%202025-02-24%20123608.png)


3.3.In the AWS Management Console, head to the Amazon EventBridge dashboard and verify that the you have two rules that were successfully created `daily-backup` & `ec2-failure-detection`

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/63459bf5ad3e63b6c2ff2c720d54a799a64b29e4/img/Screenshot%202025-02-24%20124130.png)


3.4.In the AWS Management Console, head to the Amazon SNS dashboard and verify that the `backup-alerts-topic` was successfully created and Note you must create a subscription for your topic in order to receive notifications through your emails

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/3f71b70fff3e77acff434eaa8f23ab414a0df508/img/Screenshot%202025-02-24%20125052.png)


3.5.In the AWS Management Console, head to the Amazon EC2 dashboard and verify that the Backup-Prod-EC2 was successfully created with EBS Volume attached to it 

![image_alt]()


## Step 4: let's invoke the ebs-backup-lambda-function

4.1.This will find a EC2 Instance with the tag `Backup-Prod-EC2` then create a EBS Snapshot form attached Volume store the backup snapshot in S3 Glacier and send a message to SNS confirming that snapshot was successfully backed in Amazon S3 


4.2.Go to your `ebs-backup-Lambda` function in AWS Console:

1.Click `"Test"` at the top.

2.Create a new test event (Choose "Create new test event")

3.Enter the following sample test event JSON:

```language
json
{
  "detail-type": "Scheduled Backup Trigger",
  "source": "aws.events"
}
```

4.Save the test event.

5.Click `"Test"` to invoke the function.


![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/f5a3de86082ff24566b4c87a0e9be99a2b6267ca/img/Screenshot%202025-02-24%20150123.png)



## Verify Snapshot Creation in AWS Console

1.Go to the AWS ` EC2 Console`

2.In the left menu, click `"Snapshots"` (under Elastic Block Store).


3.Look for a new snapshot created for your EC2 instance’s EBS volume.


![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/780def67da5f9efbe1fc9140ebad42a2030c1893/img/Screenshot%202025-02-24%20150250.png)


## Check if Metadata is Saved in S3

1.Go to the `AWS S3` 

2.Open your S3 bucket where metadata is stored (`S3_BUCKET variable in Lambda`).

3.Navigate to the `backups/ folder.`

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/7d6e05b15f49e14032a8a98cf166acfd981957de/img/Screenshot%202025-02-24%20150316.png)


4.Look for a file named like:

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/3f8a7525249300b16f4b9b156c9d364d78b4475a/img/Screenshot%202025-02-24%20150327.png)


5.Download & open the JSON file to verify the snapshot metadata is stored correctly.



## Confirm SNS Notification Received

1.Go to the SNS `Console' 

2.Open your SNS topic (check SNS_TOPIC_ARN in your Lambda).

3.Check email/SMS/other endpoints subscribed to the SNS topic.

4.You should receive a message like:

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/81e1145c492db93eefda4aaeb7d304849261d5c7/img/Screenshot%202025-02-24%20150438.png)


## Check Lambda Logs in CloudWatch

1.Check Lambda Logs in CloudWatch


![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/5372820af3988701c16faef6d473fa6661fc17f5/img/Screenshot%202025-02-24%20150641.png)


## Step 5: lets test the Backup & Recovery System

## Manually Stop the EC2 Instance

1.Go to the AWS Management Console.

2.Navigate to EC2 > Instances.

3.Find the instance tagged as Backup-Recovery-EC2.

4.Click Instance State > Stop Instance.

5.Wait for the instance to fully stop.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/c50a041205e95c86161254bb76a5b8b6934b9da4/img/Screenshot%202025-02-24%20160105.png)



## Check SNS Notifications

1.Open the `Amazon SNS Console.`

2.Navigate to Topics > `backup-alerts-topic.`

3.Click on Subscriptions to see where notifications are sent.

4.Check your` email/SMS/` other endpoints for alerts.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/da89bc2aab3f03dfbedfe5727a4a4e41a99410bc/img/Screenshot%202025-02-24%20153654.png)


## Verify a New EC2 Instance is Launched

1.Go to EC2 > Instances.

2.Look for a new `EC2 instance` being launched automatically.

![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/f78031a726d3c28a9a6ce27c08ed8c024d6a4979/img/Screenshot%202025-02-24%20153840.png)





## Check Lambda Logs in CloudWatch

1.Here is the cloudwatch logs verifying that both the instance and EBS Volume has failed, Now the latest snapshot is creating a new volume to create a new instance.


![image_alt](https://github.com/Tatenda-Prince/CloudVault-Secure-Backup-Recovery-Vault/blob/4236445db29907a494839d4ca544ade2f48c0912/img/Screenshot%202025-02-24%20153628.png)



## Congratulations

We have successfully created "Automated Secure Backup & Recovery Vault"  that integrates AWS services like EC2, EBS, S3, SNS, EventBridge, and CloudWatch which Terraform deploys. This system generates EBS snapshots automatically while saving metadata to S3 and delivering notifications through SNS for dependable backup and disaster recovery operations. Through the project we gained expertise in provisioning AWS resources with Terraform while learning to handle IAM roles and security policies alongside automating snapshot creation and storage through event-driven architecture for backup automation. Our debugging work included fixing infrastructure problems by verifying security groups placement within the right VPCs and correctly managing IAM permissions. We have gained essential practical knowledge in IaC and AWS automation while learning cloud security best practices which equipped us to handle real-world cloud engineering tasks.



















































