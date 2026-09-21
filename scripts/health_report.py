import boto3

REGION = "us-east-1"

ec2 = boto3.client("ec2", region_name=REGION)

print("SecureScale Infrastructure Health Report")
print("----------------------------------------")

response = ec2.describe_instances(
    Filters=[
        {
            "Name": "tag:Project",
            "Values": ["SecureScale"]
        },
        {
            "Name": "instance-state-name",
            "Values": ["running"]
        }
    ]
)

instance_count = 0

for reservation in response["Reservations"]:
    for instance in reservation["Instances"]:
        instance_count += 1

        instance_id = instance["InstanceId"]
        state = instance["State"]["Name"]
        private_ip = instance.get("PrivateIpAddress", "N/A")

        print(f"Instance ID: {instance_id}")
        print(f"State:       {state}")
        print(f"Private IP:  {private_ip}")
        print("----------------------------------------")

print(f"Total running SecureScale instances: {instance_count}")