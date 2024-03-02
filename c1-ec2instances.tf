resource "aws_instance" "RailDocker" {
  ami                    = "ami-0440d3b780d96b29d"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.raildocker-public-subnet.id
  key_name               = "Oje"
  vpc_security_group_ids = [aws_security_group.raildocker-sg.id]
  user_data              = <<-EOF
    #!/bin/bash
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

    # Install Ruby and RubyGems
    sudo yum -y install  ruby ruby-devel

    # Clone the Rails project repository
    sudo git clone https://github.com/Ojeranti08/Ruby-on-Rails-Project.git /home/ec2-user/Ruby-on-Rails-Project

    # Build and run Rails application using Docker Compose
    cd /home/ec2-user/Ruby-on-Rails-Project
    sudo docker-compose up -d

    # Run docker run command to create a new Rails app
    docker run --rm -v $(pwd):/app ruby:3.2.0 rails new . --force --database=postgresql

    # Print the master.key
    echo "RAILS_MASTER_KEY=$MASTER_KEY"

    # Save the master.key to a .env file
    echo "RAILS_MASTER_KEY=$MASTER_KEY" > .env

    # Update database.yml
    cat > config/database.yml <<EOL
    default: &default
      adapter: postgresql
      encoding: unicode
      pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
      username: postgres
      password: <%= ENV['POSTGRES_PASSWORD'] %>
      host: db

    development:
      <<: *default
      database: myapp_development

    test:
      <<: *default
      database: myapp_test

    production:
      <<: *default
      database: myapp_production
    EOL

    # Build and run the containers
    docker-compose up --build
  EOF
  private_ip             = "10.0.1.18"

  tags = {
    Name = "Rail-Docker"
  }
}
