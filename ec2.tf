provider "aws" {
  region     = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_security_group" "ES" {
  name        = "ES"
  description = "Allow traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "SSH port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ES"
  }
}


data "aws_ami" "es" {
most_recent = true
owners = ["amazon"] # AWS

  filter {
      name   = "name"
      values = ["amzn-ami-hvm-2018.03.0*"]
  }

  filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }  
}

resource "aws_instance" "ES" {
  ami = data.aws_ami.es.id
  instance_type = "t2.micro"
  key_name = "tejas_1309"
  security_groups = [ aws_security_group.ES.name ]
  vpc_security_group_ids = [ aws_security_group.ES.id ]
user_data=<<EOF
#!/bin/bash
sudo yum remove java-1.7* -y
sudo yum install java-1.8* -y
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.1-x86_64.rpm
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.9.1-x86_64.rpm.sha512
shasum -a 512 -c elasticsearch-7.9.1-x86_64.rpm.sha512
sudo rpm --install elasticsearch-7.9.1-x86_64.rpm
sudo sed -i 's/Xms1g/Xms512m/g' /etc/elasticsearch/jvm.options
sudo sed -i 's/Xmx1g/Xmx512m/g' /etc/elasticsearch/jvm.options
sudo sed -i '$ a\xpack.security.enabled: true' /etc/elasticsearch/elasticsearch.yml
sudo -i service elasticsearch start
sleep 1m
echo "y" |sudo /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto -u "http://localhost:9200" > /tmp/password.txt
sleep 10
mkdir /tmp/cert_blog
touch /tmp/cert_blog/instance.yml
sudo tee -a /tmp/cert_blog/instance.yml > /dev/null <<EOT
# add the instance information to yml file
instances:
  - name: 'node1'
    dns: [ 'node1.elastic.test.com' ]
EOT
sudo tee -a /etc/hosts > /dev/null <<EOT
127.0.0.1 node1.elastic.test.com node1
EOT
/usr/share/elasticsearch/bin/elasticsearch-certutil cert --keep-ca-key --pem --in /tmp/cert_blog/instance.yml --out /tmp/cert_blog/certs.zip
cd /tmp/cert_blog
unzip certs.zip -d ./certs
sleep 5
mkdir /etc/elasticsearch/certs
cd /etc/elasticsearch/certs
cp /tmp/cert_blog/certs/ca/ca* /tmp/cert_blog/certs/node1/* /etc/elasticsearch/certs
sudo tee -a /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOT
node.name: node1
network.host: node1.elastic.test.com
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.key: certs/node1.key
xpack.security.http.ssl.certificate: certs/node1.crt
xpack.security.http.ssl.certificate_authorities: certs/ca.crt
xpack.security.transport.ssl.key: certs/node1.key
xpack.security.transport.ssl.certificate: certs/node1.crt
xpack.security.transport.ssl.certificate_authorities: certs/ca.crt
discovery.seed_hosts: [ "node1.elastic.test.com" ]
cluster.initial_master_nodes: [ "node1" ]
EOT
sudo chkconfig --add elasticsearch
sudo -i service elasticsearch restart
EOF
  tags = {
    Name = "ES-setup"
  }
}