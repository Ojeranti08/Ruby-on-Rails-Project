resource "aws_instance" "RailDocker" {
  ami                    = "ami-002070d43b0a4f171"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.raildocker-public-subnet.id
  key_name               = "Kemi"
  vpc_security_group_ids = [aws_security_group.raildocker-sg.id]
  user_data              = <<-EOF
   #!/bin/bash

   # Update the system
   #sudo yum update -y

   # Install necessary packages
   sudo yum install -y git docker 

   # Start Docker service
   sudo systemctl start docker
   sudo systemctl enable docker

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose

   # Install Ruby and other dependencies
   # sudo yum update -y
   sudo yum install git -y
   sudo yum -y install ruby -v 3.2.0
   sudo yum -y groupinstall "Development Tools"
   sudo gem install bundler
   gem update --system
   sudo yum -y install ruby-devel
   gem install rails -v 6.1.4
   sudo yum -y install postgresql-devel
   sudo yum -y install postgresql
   sudo yum -y install sqlite-devel
   bundle install
   bundle install --gemfile

   # Clone the Rails Project repository
   sudo git clone https://github.com/Ojeranti08/Ruby-on-Rails-Project.git /home/ec2-user/Ruby-on-Rails-Project

   cd /home/ec2-user/Ruby-on-Rails-Project

   # Run docker run command to create a new Rails app
   rails new rails-docker --apl --database=postgresql

   cd /home/ec2-user/Ruby-on-Rails-Project/rails-docker

   # Remove files
    sudo rm -rf Dockerfile Gemfile \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config/database.yaml \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config/routes.rb \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/bin/docker-entrypoint

    # Move files
    mv /home/ec2-user/Ruby-on-Rails-Project/Dockerfile \
        /home/ec2-user/Ruby-on-Rails-Project/env \
        /home/ec2-user/Ruby-on-Rails-Project/.ruby-version \
        /home/ec2-user/Ruby-on-Rails-Project/docker-entrypoint \
        /home/ec2-user/Ruby-on-Rails-Project/database.yaml \
        /home/ec2-user/Ruby-on-Rails-Project/routes.rb \
        /home/ec2-user/Ruby-on-Rails-Project/Gemfile \
        /home/ec2-user/Ruby-on-Rails-Project/Gemfile.lock \
        /home/ec2-user/Ruby-on-Rails-Project/docker-compose.yaml \
        /home/ec2-user/Ruby-on-Rails-Project/Dockerfile-PostgresSQL \
        .

    mv   /home/ec2-user/Ruby-on-Rails-Project/boot.rb \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config

    # Move and rename files
    mv /home/ec2-user/rails-docker/Ruby-on-Rails-Project/docker-entrypoint \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/bin

    mv /home/ec2-user/rails-docker/Ruby-on-Rails-Project/database.yaml \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config

    mv /home/ec2-user/rails-docker/Ruby-on-Rails-Project/routes.rb \
        /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config
   
   sudo chown ec2-user:ec2-user /home/ec2-user/Ruby-on-Rails-Project/rails-docker/Gemfile.lock
   sudo chmod +w /home/ec2-user/Ruby-on-Rails-Project/rails-docker/Gemfile.lock
   bundle install

   # Print the master.key
   echo "RAILS_MASTER_KEY=$MASTER_KEY"

   # Save the master.key to a env file
   echo "RAILS_MASTER_KEY=$MASTER_KEY" > env

   # Generate the scaffold for the "Post" model
   rails g scaffold post title body:text

   # Build and run the containers
   docker-compose build && docker-compose up
  EOF

  private_ip = "10.0.1.18"

  tags = {
    Name = "Rail-Docker"
  }
}
