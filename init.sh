#!/bin/bash

# Establish the bae variable's we'll need. 

SECURITY_GROUP=esearch-sg
SECURITY_GROUP_ID=sg-7bf86100
AMI=ami-4836a428
INSTANCE=i-00a85ad003d01f8ee
EC2_IP=35.165.215.96
OUR_IP=$(curl -s ipinfo.io/ip)
EC2_KEY=elasticsearch-key.pem
# That'll do. 

# Introduce the user that doesn't read the code to what we're going to do and use. 
echo "Welcome! We are going to build Elasticsearch from scratch. "
sleep 1

echo "Here's what we know so far: "
echo "Security Group..................................................: $SECURITY_GROUP"
echo "Security Group ID...............................................: $SECURITY_GROUP_ID"
echo "AMI.............................................................: $AMI"
echo "Instance........................................................: $INSTANCE"
echo "EC2 IP Address..................................................: $EC2_IP"
echo "Our Machine IP..................................................: $OUR_IP"
echo "Our EC2 Key.....................................................: $EC2_KEY"
sleep 2

echo " "
echo "Confirm if $SECURITY_GROUP exists as the first Security Group in your AWS instance."

if [[ $(aws ec2 describe-security-groups --group-names esearch-sg --query SecurityGroups[0].GroupName | sed 's/\[//' | sed -e 's/\"//g') -eq "$securityGroup" ]]; then 
	echo "It does! Nothing to be done, then."
	echo " "
else 
	echo "They do not match, so let's make the group."
	aws ec2 create-security-group --group-name "$securityGroup" --description "security group for elastic search environment in EC2" 
	# Make sure we have the security group ID stored for later, when we need to make the instance. 
	SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --group-names esearch-sg --query SecurityGroups[0].GroupId | sed 's/\"//g')
	echo "We will also need to allow incoming/outgoing traffic, taking care of that. "
	aws ec2 authorize-security-group-ingress --group-name "$SECURITY_GROUP" --protocol tcp --port "9200" --cidr "$OUR_IP"/32
	aws ec2 authorize-security-group-ingress --group-name "$SECURITY_GROUP" --protocol tcp --port "22" --cidr "$OUR_IP"/32
	aws ec2 authorize-security-group-egress --group-id "$SECURITY_GROUP_ID " --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 0, "ToPort": 65535, "IpRanges": [{"CidrIp": "0.0.0.0/0"}]}]'
	echo " " 
fi 

echo "Confirming if we have keys properly established for our EC2 instance. "
if [[ -f "$EC2_KEY" ]]; then 
	#echo $(cat "$EC2_KEY")
	echo "Yes, we have an EC2 key stored as $EC2_KEY"
	echo " "
else 
	aws ec2 create-key-pair --key-name elasticsearch-key --query 'KeyMaterial' --output text > elasticsearch-key.pem
	echo " "
fi

echo "Next, let's see if we have an EC2 instance that matches - expecting: $INSTANCE"
# Things became a mess where Amazon values became octals in bash. Ugh. 
AWS_INSTANCE=$(aws ec2 describe-instances --query Reservations[].Instances[].InstanceId | sed -e 's/\[//' -e 's/\]//' -e 's/\"//g' -e '/^\s*$/d' -e 's/^    //')		
if [[ "$AWS_INSTANCE" == "$INSTANCE" ]]; then 
	echo "Confirmed, you have an instance with the correct Instance ID. "
	echo " " 
else 
	echo "Looks like we still need to make the instance, let's do it. "
	INSTANCE=$(aws ec2 run-instances --image-id "$AMI" --security-group-ids "$SECURITY_GROUP_ID" --count 1 --instance-type t2.micro --key-name elasticsearch-key --query 'Instances[0].InstanceId' | sed 's/\"//g')
	# Store the instance value. 
	echo "$INSTANCE"
	# Make sure the script is updated to the new value. 
	sed -i.bak "s/^INSTANCE=.*$/INSTANCE=$INSTANCE/" init.sh
	rm -rf init.sh.bak
	echo " "
fi  

echo "Fetching the public IP address of our instance and storing it."
IP=$(aws ec2 describe-instances --query 'Reservations[].Instances[].PublicIpAddress' | sed -e 's/\[//' -e 's/\]//' -e 's/\"//g' -e '/^\s*$/d' -e 's/^    //')
# Make sure the script is updated to the new value. 
sed -i.bak "s/^EC2_IP=.*$/EC2_IP=$IP/" init.sh
rm -rf init.sh.bak
echo "$EC2_IP"
echo " "
sleep 1

echo "Now we have everything needed to connect to the instance and install ElasticSearch!"
echo "Hang tight while we sleep five minutes to make sure the instance is up and running."
echo " "
sleep 300

echo "We'll use rsync instead of SCP to only copy the ElasticSearch zip if it's needed. "
rsync -a --ignore-existing -rave "ssh -i $EC2_KEY" es.zip ec2-user@$EC2_IP:~/
echo " "
sleep 1

echo "Unfortunately our EC2 probably doesn't have the required version of Java. This has literally never ever happened before. ;)"
echo "Let's install Java 1.8 and remove 1.7"
ssh -i $EC2_KEY ec2-user@$EC2_IP /bin/bash << EOF
	sudo yum -y install java-1.8.0
	sudo yum -y remove java-1.7.0-openjdk
EOF
echo " " 
sleep 1

echo "Add some swap space to deal with elastic search wanting more memory"
# "TODO! Make this dynamic and only happen once."
ssh -i $EC2_KEY ec2-user@$EC2_IP 'sudo dd if=/dev/zero of=/swapfile bs=1M count=3800;sudo mkswap /swapfile; sudo swapon /swapfile' 
echo " "
sleep 1

echo "Unzip ElasticSearch:"
ssh -i $EC2_KEY ec2-user@$EC2_IP 'unzip -n es.zip'
echo " "
sleep 1

echo "Install X-Pack, so we can start securing things: "
ssh -i $EC2_KEY ec2-user@$EC2_IP 'cd es/bin; ./elasticsearch-plugin -s install x-pack'
echo " "
sleep 1

echo "Copying certificate blueprint to our server if needed."
rsync -a --ignore-existing -rave "ssh -i $EC2_KEY" instances.yml ec2-user@$EC2_IP:~/

# Last round quick tinkering to get certificates & SSL up and running. 
# es/bin/x-pack/certgen -in ~/instances.yml
# unzip /home/ec2-user/es/config/x-pack/certificate-bundle.zip
# echo "xpack.ssl.key: /home/es/config/x-pack/my_node_name.key" >> /home/ec2-user/es/config/elasticsearch.yml
# echo "xpack.ssl.certificate: /home/es/config/x-pack/my_node_name.crt" >> /home/ec2-user/es/config/elasticsearch.yml
# echo "xpack.ssl.certificate_authorities: [ '/home/es/config/x-pack/ca.crt' ]" >> /home/ec2-user/es/config/elasticsearch.yml
# echo "xpack.security.transport.ssl.enabled: true" >> /home/ec2-user/es/config/elasticsearch.yml
# echo "xpack.security.http.ssl.enabled: true" >> /home/ec2-user/es/config/elasticsearch.yml

echo "Let's launch ElasticSearch so we don't need to worry about relaunching it later, unless the box reboots (launch as daemon): "
ssh -i $EC2_KEY ec2-user@$EC2_IP 'cd /home/ec2-user/es/bin; ./elasticsearch  -Ecluster.name=my_cluster -Enode.name=my_node_name -d'
echo "Sleeping for 20 seconds to let things get settled. "
sleep 20

ssh -i $EC2_KEY ec2-user@$EC2_IP /bin/bash << EOF
echo "Let's prove that we NEED to use authentication, by requesting without any credentials: "
echo " "
curl -s -XGET 'http://localhost:9200/'
echo " "
sleep 2

echo "Hmm, that didn't look too good, did it? Let's use the default un/pw and see the node is responsive: "
echo " "
curl -s -XGET 'http://localhost:9200/' -u elastic:changeme
sleep 2
echo " "

echo "Great. Let's just update the password to something a _little_ more secure (we'll use elasticpassword): "
echo " "
curl -POST -u elastic:changeme 'localhost:9200/_xpack/security/user/elastic/_password' -H "Content-Type: application/json" -d '{
  "password" : "elasticpassword"
}'
sleep 2
echo " "

echo "Alright! Let's use the new password now, to confirm everything: " 
echo " "
curl -XGET 'http://localhost:9200/' -u elastic:elasticpassword
sleep 2
echo " "
echo "ELASTICSEARCH INSTALLED, RUNNING, AND SECURED WITH A NON-DEFAULT PASSWORD/"
EOF
