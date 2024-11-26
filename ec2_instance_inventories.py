import boto3
import csv
import json
import argparse
from prettytable import PrettyTable

def get_ec2_instances(region):
    # Create a session using the specified region
    session = boto3.Session(region_name=region)
    ec2_resource = session.resource('ec2')

    # List to store instance details
    instance_details = []

    # Iterate over all instances in the specified region
    for instance in ec2_resource.instances.all():
        # Get the instance name from tags
        instance_name = None
        for tag in instance.tags or []:
            if tag['Key'] == 'Name':
                instance_name = tag['Value']
                break

        details = {
            'Instance ID': instance.id,
            'Instance Name': instance_name,
            'Instance Type': instance.instance_type,
            'State': instance.state['Name'],
            'Public IP Address': instance.public_ip_address,
            'Private IP Address': instance.private_ip_address,
            'Private DNS Name': instance.private_dns_name,
            'Launch Time': instance.launch_time
        }
        instance_details.append(details)

    return instance_details

def print_table(instances):
    table = PrettyTable()
    table.field_names = ["Instance ID", "Instance Name", "Instance Type", "State", 
                         "Public IP Address", "Private IP Address", "Private DNS Name", "Launch Time"]

    for instance in instances:
        table.add_row([
            instance['Instance ID'],
            instance['Instance Name'] if instance['Instance Name'] else 'N/A',
            instance['Instance Type'],
            instance['State'],
            instance['Public IP Address'] if instance['Public IP Address'] else 'N/A',
            instance['Private IP Address'] if instance['Private IP Address'] else 'N/A',
            instance['Private DNS Name'] if instance['Private DNS Name'] else 'N/A',
            instance['Launch Time']
        ])

    print(table)

def print_csv(instances):
    with open('ec2_instances.csv', 'w', newline='') as csvfile:
        fieldnames = ["Instance ID", "Instance Name", "Instance Type", "State", 
                      "Public IP Address", "Private IP Address", "Private DNS Name", "Launch Time"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)

        writer.writeheader()
        for instance in instances:
            writer.writerow({
                "Instance ID": instance['Instance ID'],
                "Instance Name": instance['Instance Name'] if instance['Instance Name'] else 'N/A',
                "Instance Type": instance['Instance Type'],
                "State": instance['State'],
                "Public IP Address": instance['Public IP Address'] if instance['Public IP Address'] else 'N/A',
                "Private IP Address": instance['Private IP Address'] if instance['Private IP Address'] else 'N/A',
                "Private DNS Name": instance['Private DNS Name'] if instance['Private DNS Name'] else 'N/A',
                "Launch Time": instance['Launch Time']
            })

    print("Output written to ec2_instances.csv")

def print_json(instances):
    with open('ec2_instances.json', 'w') as jsonfile:
        json.dump(instances, jsonfile, default=str, indent=4)

    print("Output written to ec2_instances.json")

if __name__ == "__main__":
    # Set up argument parsing
    parser = argparse.ArgumentParser(description='Extract EC2 instance details from a specified AWS region.',
                                     epilog='Example usage:\n'
                                            '  python extract_ec2_instances.py --region ap-southeast-1 --output table\n'
                                            '  python extract_ec2_instances.py --region us-east-1 --output csv\n'
                                            '  python extract_ec2_instances.py --region eu-west-1 --output json\n'
                                            'Make sure you have the necessary AWS credentials configured.')

    parser.add_argument('--region', type=str, required=True, help='The AWS region (e.g., ap-southeast-1).')
    parser.add_argument('--output', type=str, choices=['table', 'csv', 'json'], required=True,
                        help='The output format (table, csv, or json).')

    args = parser.parse_args()

    try:
        instances = get_ec2_instances(args.region)

        if args.output == 'table':
            print_table(instances)
        elif args.output == 'csv':
            print_csv(instances)
        elif args.output == 'json':
            print_json(instances)

    except Exception as e:
        print(f"An error occurred: {e}")