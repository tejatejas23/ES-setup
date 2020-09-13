ElasticSearch Cluster setup with authentication and TLS encryption enabled

this terraform code will help you to launch EC2 instance with Elastic search install in it
i have use AWS user_data to bootstrap the Elastic Search installation over EC2 and use Amazon Linux machine to perform the action

all the action performed as part of User data has been referred from below website
https://www.elastic.co/

to successfully perform ES deployment kindly update below value in variables.tf
1. access_key
2. Secret_key
3. your public IP for SSH access

once server is up kindly use below command to access elastic search
curl --cacert /tmp/cert_blog/certs/ca/ca.crt -u elastic:`awk '{print $4}' /tmp/password.txt | tail -2` 'https://node1.elastic.test.com:9200/_cat/nodes?v'
