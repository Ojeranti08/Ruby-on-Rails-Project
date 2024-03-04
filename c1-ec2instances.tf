resource "aws_instance" "RailDocker" {
  ami                    = "ami-0440d3b780d96b29d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.raildocker-public-subnet.id
  key_name               = "Oje"
  vpc_security_group_ids = [aws_security_group.raildocker-sg.id]
  user_data              = <<-EOF
   #!/bin/bash

   # Update the system
   sudo yum update -y

   # Install necessary packages
   sudo yum install -y git docker 

   # Start Docker service
   sudo systemctl start docker
   sudo systemctl enable docker

   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose

   # Install Rails
   sudo yum -y install ruby
   sudo yum -y groupinstall "Development Tools"
   gem install bundler
   sudo yum -y install ruby-devel
   #sudo gem install rails

   
   # Install Rails (without -y flag, as gem install doesn't accept it)
   sudo yum remove ruby -y
   sudo yum remove ruby-devel -y
   sudo yum -y install ruby
   sudo yum install ruby-devel -y

   # Install Rails
   sudo gem install rails -v 7.0.4

   # Clone the Rails Project repository
   sudo git clone https://github.com/Ojeranti08/Ruby-on-Rails-Project.git /home/ec2-user/Ruby-on-Rails-Project

   cd /home/ec2-user/Ruby-on-rails-project

    # Run docker run command to create a new Rails app
    rails new rails-docker --apl --database=postgresql

    cd /home/ec2-user/Ruby-on-rails-project/rails-docker

    # Remove files
    sudo rm -rf Dockerfile Gemfile \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config/database.yaml \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config/routes.rb \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/bin/docker-entrypoint

    # Move files
    mv /home/ec2-user/Ruby-on-rails-project/Dockerfile \
        /home/ec2-user/Ruby-on-rails-project/env \
        /home/ec2-user/Ruby-on-rails-project/.ruby-version \
        /home/ec2-user/Ruby-on-rails-project/docker-entrypoint \
        /home/ec2-user/Ruby-on-rails-project/database.yaml \
        /home/ec2-user/Ruby-on-rails-project/routes.rb \
        /home/ec2-user/Ruby-on-rails-project/Gemfile \
        /home/ec2-user/Ruby-on-rails-project/Gemfile.lock \
        /home/ec2-user/Ruby-on-rails-project/docker-compose.yaml \
        /home/ec2-user/Ruby-on-rails-project/Dockerfile-PostgresSQL \
        .
    # Move and rename files
    mv /home/ec2-user/rails-docker/Ruby-on-rails-project/docker-entrypoint \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/bin

    mv /home/ec2-user/rails-docker/Ruby-on-rails-project/database.yaml \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config

    mv /home/ec2-user/rails-docker/Ruby-on-rails-project/routes.rb \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config


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
