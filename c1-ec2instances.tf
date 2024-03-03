resource "aws_instance" "RailDocker" {
  ami                    = "ami-0440d3b780d96b29d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.raildocker-public-subnet.id
  key_name               = "Oje"
  vpc_security_group_ids = [aws_security_group.raildocker-sg.id]
  user_data              = <<-EOF
    #!/bin/bash

    # Update the System & Install Git & Docker
    sudo yum update -y
    sudo yum -y install git docker

    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Install Docker
    curl -fsSL https://get.docker.com -o install-docker.sh
    sudo sh install-docker.sh
    sudo systemctl start docker
    sudo systemctl enable docker

    # Install Ruby
    sudo yum -y install ruby

    # Install Development Tools (optional but recommended for compiling native extensions)
    sudo yum -y groupinstall "Development Tools"

    # Install Bundler (without -y flag, as gem install doesn't accept it)
    gem install bundler

    # Install Ruby development headers (necessary for building certain Ruby gems)
    sudo yum install ruby-devel -y 

    # Set GEM_HOME and GEM_PATH
    echo 'export GEM_HOME=$HOME/.local/share/gem/ruby' >> ~/.bashrc
    echo 'export GEM_PATH=$GEM_HOME:/usr/share/ruby3.2-gems:/usr/share/gems:/usr/local/share/ruby3.2-gems:/usr/local/share/gems' >> ~/.bashrc

    # Add Ruby gems binary directory to PATH
    echo 'export PATH=$PATH:$GEM_HOME/bin' >> ~/.bashrc
    source ~/.bashrc 

    # Install Rails (without -y flag, as gem install doesn't accept it)
    sudo yum remove ruby -y
    sudo yum remove ruby-devel -y
    sudo yum install ruby -y
    sudo yum install ruby-3.2.2-devel -y
    sudo gem install rails -v 7.0.4
 
    # Clone the Rails project repository
    sudo git clone https://github.com/Ojeranti08/Ruby-on-Rails-Project.git /home/ec2-user/Ruby-on-Rails-Project

    # Build and run Rails application using Docker Compose
    cd /home/ec2-user/Ruby-on-Rails-Project

    # Run docker run command to create a new Rails app
    rails new rails-docker --apl --database=postgresql
    
    # Change directory to rails-docker
    cd /home/ec2-user/Ruby-on-rails-project/rails-docker

    # Move the files from Ruber-on-rails-project to the correct location (rails-docker) 
    sudo mv /home/ec2-user/Ruby-on-rails-project/Dockerfile .
    sudo mv /home/ec2-user/Ruby-on-rails-project/Gemfile .
    sudo mv /home/ec2-user/Ruby-on-rails-project/docker-compose.yaml .
    sudo mv /home/ec2-user/Ruby-on-rails-project/dockerfile.postgres .
    sudo mv /home/ec2-user/Ruby-on-rails-project/docker-entrypoint /home/ec2-user/Ruby-on-rails-project/rails-docker/bin
    sudo mv /home/ec2-user/Ruby-on-rails-project/database.yaml /home/ec2-user/Ruby-on-rails-project/rails-docker/config
    sudo mv /home/ec2-user/Ruby-on-rails-project/routes.rb /home/ec2-user/Ruby-on-rails-project/rails-docker/config
    sudo mv /home/ec2-user/Ruby-on-rails-project/.env /home/ec2-user/Ruby-on-rails-project/rails-docker
    
    cd /home/ec2-user/Ruby-on-rails-project
    sudo rm -rf Dockerfile
    sudo rm -rf Gemfile 
    sudo rm -rf /home/ec2-user/Ruby-on-rails-project/database.yaml
    sudo rm -rf /home/ec2-user/Ruby-on-rails-project/routes.rb
    sudo rm -rf /home/ec2-user/Ruby-on-rails-project/docker-entrypoint

    cd /home/ec2-user/Ruby-on-rails-project/rails-docker 

    # Print the master.key
    echo "RAILS_MASTER_KEY=$MASTER_KEY"

    # Save the master.key to a .env file
    echo "RAILS_MASTER_KEY=$MASTER_KEY" > .env

    rails g scaffold post title body:text

    # Build and run the containers
    docker-compose up --build
  EOF

  private_ip = "10.0.1.18"

  tags = {
    Name = "Rail-Docker"
  }
}
