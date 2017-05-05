#!/bin/bash
# Set up some initial variables we will use at various times: 
securityGroup=esearch-sg
AMI=ami-4836a428
instance=i-0338d7b3fa3c53e2c
ipaddress=35.165.160.179

if [[ $# -ne 0 ]]; then 
	# Just a basic check to confirm an argument exists. 
	if [[ "$1" = "initialize" ]]; then 
		echo "The arguement is to initialize! "
		echo "Initialize a security group for our new EC2 instance:"
		#aws ec2 create-security-group --group-name "$securityGroup" --description "security group for elastic search environment in EC2" --dry-run 

		echo "Let's allow traffic over port 22:"
		#aws ec2 authorize-security-group-ingress --group-name "$securityGroup" --protocol tcp --port 9200 --cidr 23.79.236.14/0

		echo "Create a key-pair for access: "
		#aws ec2 create-key-pair --key-name elasticsearch-key --query 'KeyMaterial' --output text > elasticsearch-key.pem
		# todo - clean up permissions

		echo "Create an EC2 instance:"
		# TODO - send the resulting string to the $instance variable above. 
		#aws ec2 run-instances --image-id "$AMI" --security-group-ids sg-7bf86100 --count 1 --instance-type t2.micro --key-name elasticsearch-key --query 'Instances[0].InstanceId'

		echo "Let's fetch the public IP address of our instance:"
		# TODO - send the resulting string to the $ipaddress variable above. 
		#aws ec2 describe-instances --instance-ids "$instance" --query 'Reservations[0].Instances[0].PublicIpAddress'

		echo "Blow away Java 1.7 and install 1.8, lol. Did I expect to not have to do this.... naive?"
		#ssh -i elasticsearch-key.pem ec2-user@"$ipaddress" 'sudo yum install java-1.8.0; sudo yum remove java-1.7.0-openjdk'

		echo "Add some swap space to deal with elastic search wanting more memory"
		#ssh -i elasticsearch-key.pem ec2-user@"$ipaddress" 'sudo dd if=/dev/zero of=/swapfile bs=1M count=5000;sudo mkswap /swapfile; sudo swapon /swapfile' \\

		echo "Download, unzip ElasticSearch:"
		ssh -i elasticsearch-key.pem ec2-user@"$ipaddress" 'curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.0.tar.gz; tar -xvf elasticsearch-5.4.0.tar.gz'

		echo "Install X-Pack, so we can start securing things: "
		ssh -i elasticsearch-key.pem ec2-user@"$ipaddress" 'cd elasticsearch-5.4.0/bin; ./elasticsearch-plugin install x-pack'

		echo "Let's launch ElasticSearch as a daemon so we don't need to worry about relaunching it later, unless the box reboots: "
		ssh -i elasticsearch-key.pem ec2-user@"$ipaddress" 'cd elasticsearch-5.4.0/bin; ./elasticsearch  -Ecluster.name=my_cluster -Enode.name=my_node_name -d'
		echo "Sleeping for 20 seconds to let things get settled. "
		sleep 20
	fi
fi

#ssh -i elasticsearch-key.pem ec2-user@35.165.160.179




ssh -i elasticsearch-key.pem ec2-user@"$ipaddress" /bin/bash << EOF
echo "Let's prove that we NEED to use authentication, by requesting without any credentials: "
curl -XGET 'http://localhost:9200/'
sleep 1

echo
echo "Hmm, that didn't look too good, did it? Let's use the default un/pw and see the node is responsive: "
curl -XGET 'http://localhost:9200/' -u elastic:changeme
sleep 1

echo
echo "Great. Let's just update the password to something a _little_ more secure (we'll use elasticpassword): "
curl -POST -u elastic:changeme 'localhost:9200/_xpack/security/user/elastic/_password' -H "Content-Type: application/json" -d '{
  "password" : "elasticpassword"
}'
sleep 1

echo
echo "Alright! Let's use the new password now, to confirm everything: " 
curl -XGET 'http://localhost:9200/' -u elastic:elasticpassword
EOF

