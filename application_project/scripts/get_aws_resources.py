import boto3
import json
import os
import sys

def get_subnets(name_prefix):
    ec2 = boto3.client('ec2')
    response = ec2.describe_subnets(
        Filters=[
            {
                'Name': 'tag:Name',
                'Values': [f'{name_prefix}app1_lb*']
            }
        ]
    )
    return [subnet['SubnetId'] for subnet in response['Subnets']]

def get_iam_role_arn(name_prefix):
    iam = boto3.client('iam')
    role_name = f"{name_prefix}eks-pod-role"
    response = iam.get_role(RoleName=role_name)
    return response['Role']['Arn']

def get_gwlb_endpoint_info(unique_id):
    try:
        ec2 = boto3.client('ec2')
        response = ec2.describe_vpc_endpoints(
            Filters=[
                {'Name': 'tag:Name', 'Values': [f'{unique_id}eastwest*']},
                {'Name': 'vpc-endpoint-type', 'Values': ['GatewayLoadBalancer']}
            ]
        )
        if not response['VpcEndpoints']:
            print(f"Error: No matching GWLB endpoints found for unique_id: {unique_id}", file=sys.stderr)
            return []
        
        eni_ids = [endpoint['NetworkInterfaceIds'][0] for endpoint in response['VpcEndpoints']]
        eni_info = ec2.describe_network_interfaces(NetworkInterfaceIds=eni_ids)
        endpoints = [
            {'ip': eni['PrivateIpAddress'], 'az': eni['AvailabilityZone']}
            for eni in eni_info['NetworkInterfaces']
        ]
        return endpoints
    except Exception as e:
        print(f"Error in get_gwlb_endpoint_info: {str(e)}", file=sys.stderr)
        return []
    
if __name__ == "__main__":
    unique_id = os.environ.get('UNIQUE_ID', '')
    if not unique_id:
        print("Error: UNIQUE_ID environment variable is not set.", file=sys.stderr)
        sys.exit(1)
    print(f"Debug: UNIQUE_ID = {unique_id}", file=sys.stderr)

    endpoints = get_gwlb_endpoint_info(unique_id)
    print(f"Debug: Found {len(endpoints)} endpoints", file=sys.stderr)
    subnets = get_subnets(unique_id)
    role_arn = get_iam_role_arn(unique_id)
    
    if len(endpoints) != 2:
        print(f"Error: Expected 2 endpoints, found {len(endpoints)}", file=sys.stderr)
        sys.exit(1)

    for i, endpoint in enumerate(endpoints, 1):
        print(f"export ENDPOINTS{i}={endpoint['ip']}")
        print(f"export ENDPOINTS{i}ZONE={endpoint['az']}")

    print(f"export SUBNETS={','.join(subnets)}")
    print(f"export ROLE_ARN={role_arn}")