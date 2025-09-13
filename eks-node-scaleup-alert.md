# EKS Node Scale-Up Email Notification Setup

This guide explains how to configure **Amazon EKS** to send email alerts
when new nodes are added to the cluster (scale-up events).\
We will use **Amazon SNS** and **Auto Scaling Group notifications**.

------------------------------------------------------------------------

## 1. Identify the Auto Scaling Group (ASG)

EKS managed node groups run on **EC2 Auto Scaling Groups**.\
Find the ASG for your node group:

``` bash
aws eks describe-nodegroup --cluster-name <your-cluster> --nodegroup-name <your-nodegroup-name>   --query "nodegroup.resources.autoScalingGroups"
```

You will get something like:

``` json
[
  {
    "name": "eks-nodegroup-xyz-NodeGroup-ABC123DEF"
  }
]
```

------------------------------------------------------------------------

## 2. Create an SNS Topic

``` bash
aws sns create-topic --name eks-node-scaleup
```

Copy the Topic ARN from the output, e.g.:\
`arn:aws:sns:ap-south-1:123456789012:eks-node-scaleup`

------------------------------------------------------------------------

## 3. Subscribe 3 Email Recipients

Run the following commands (replace with your emails):

``` bash
aws sns subscribe   --topic-arn arn:aws:sns:ap-south-1:123456789012:eks-node-scaleup   --protocol email   --notification-endpoint mail1@example.com

aws sns subscribe   --topic-arn arn:aws:sns:ap-south-1:123456789012:eks-node-scaleup   --protocol email   --notification-endpoint mail2@example.com

aws sns subscribe   --topic-arn arn:aws:sns:ap-south-1:123456789012:eks-node-scaleup   --protocol email   --notification-endpoint mail3@example.com
```

👉 Each recipient must **check their inbox** and confirm the
subscription.

------------------------------------------------------------------------

## 4. Attach ASG Notifications to SNS

Connect your Auto Scaling Group to the SNS topic:

``` bash
aws autoscaling put-notification-configuration   --auto-scaling-group-name eks-nodegroup-xyz-NodeGroup-ABC123DEF   --topic-arn arn:aws:sns:ap-south-1:123456789012:eks-node-scaleup   --notification-types autoscaling:EC2_INSTANCE_LAUNCH autoscaling:EC2_INSTANCE_TERMINATE
```

This will send notifications on **node scale-up** and **scale-down**.

------------------------------------------------------------------------

## 5. Test the Setup

-   Deploy a workload that requires more pods than current capacity.\
-   EKS Cluster Autoscaler will trigger an ASG scale-up.\
-   You should receive an email notification similar to:

```{=html}
<!-- -->
```
    Auto Scaling: launching a new EC2 instance i-0abcd1234 in group eks-nodegroup-xyz

------------------------------------------------------------------------

## ✅ Summary

-   SNS Topic created → `eks-node-scaleup`\
-   3 email subscribers added\
-   ASG configured to notify on scale-up/down

Now, whenever your **EKS node group scales**, all three recipients will
get an email alert.
