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
    sudo yum install ruby-devel -y
    sudo gem install rails -v 7.0.4
 
    # Clone the Rails Project repository
    sudo git clone https://github.com/Ojeranti08/Ruby-on-Rails-Project.git /home/ec2-user/Ruby-on-Rails-Project

    # Build and run Rails application using Docker Compose
    cd /home/ec2-user/Ruby-on-Rails-Project

    # Run docker run command to create a new Rails app
    rails new rails-docker --apl --database=postgresql

    vi Dockerfile
      user_data              = <<-EOF
    #!/bin/bash
    # Make sure it matches the Ruby version in .ruby-version and Gemfile
    ARG RUBY_VERSION=3.2.0
    FROM ruby:$RUBY_VERSION

    # Install libvips for Active Storage preview support
    RUN yum update -qq && \
    yum install -y build-essential libvips bash bash-completion libffi-dev tzdata postgresql nodejs npm yarn && \
    yum clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

    # Rails app lives here
    WORKDIR /Rails

    # Set production environment
    ENV RAILS_LOG_TO_STDOUT="1" \
    RAILS_SERVE_STATIC_FILES="true" \
    RAILS_ENV="production" \
    BUNDLE_WITHOUT="development"

    # Install application gems
    COPY Gemfile Gemfile.lock ./
    RUN bundle install

    # Copy application code
    COPY . .

    # Precompile bootsnap code for faster boot times
    RUN bundle exec bootsnap precompile --gemfile app/ lib/

    # Precompiling assets for production without requiring secret RAILS_MASTER_KEY
    RUN SECRET_KEY_BASE_DUMMY=1 bundle exec Rails assets:precompile

    # Entrypoint prepares the database.
    ENTRYPOINT ["/Rails/bin/docker-entrypoint"]

    # Start the server by default, this can be overwritten at runtime
    EXPOSE 3000
    CMD ["./bin/Rails", "server"]
   

    vi Gemfile
      user_data            = <<-EOF
      # Gemfile

      source 'https://rubygems.org'

      ruby '3.2.2'

      gem 'Rails', '7.0.4' # Adjust the version based on my Rails application requirements

      group :development, :test do
      gem 'sqlite3', '1.4.2' # Use the appropriate database gem and version for development and testing
      end

      group :production do
      gem 'pg', '1.2.3' # Use the appropriate database gem and version for production (PostgreSQL)
      end 
    
    # Change directory to rails-docker
    cd /home/ec2-user/Ruby-on-Rails-Project/rails-docker
    rm -rf Gemfile

    # Copy the files from Ruber-on-Rails-Project to the correct location (rails-docker) 
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/Dockerfile /home/ec2-user/Ruby-on-Rails-Project/rails-docker
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/Gemfile /home/ec2-user/Ruby-on-Rails-Project/rails-docker
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/docker-compose.yaml /home/ec2-user/Ruby-on-Rails-Project/rails-docker
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/Dockerfile-PostgresSQL /home/ec2-user/Ruby-on-Rails-Project/rails-docker
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/docker-entrypoint /home/ec2-user/Ruby-on-Rails-Project/rails-docker/bin
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/database.yaml /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/routes.rb /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/Gemfile.lock /home/ec2-user/Ruby-on-Rails-Project/rails-docker
    sudo cp /home/ec2-user/Ruby-on-Rails-Project/data-ignore /home/ec2-user/Ruby-on-Rails-Project/rails-docker

    # Change directory to Ruby-on-Rails-Project
    cd /home/ec2-user/Ruby-on-Rails-Project
    # sudo rm -rf Dockerfile
    # sudo rm -rf Gemfile 
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/database.yaml
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/routes.rb
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/docker-entrypoint
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/.env
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/Gemfile.lock
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/docker-compose.yaml
    # sudo rm -rf /home/ec2-user/Ruby-on-Rails-Project/Dockerfile-PostgresSQL

    # Generate a new secret key
    MASTER_KEY=$(Rails secret)

    # Create a new .env file with the new secret key
    echo "RAILS_MASTER_KEY=$MASTER_KEY" > .env

    # Move the .env file to the correct location (rails-docker)
    sudo cp .env /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config

    # Change directory to rails-docker
    cd /home/ec2-user/Ruby-on-Rails-Project/rails-docker 

    # Print the master.key
    echo "RAILS_MASTER_KEY=$MASTER_KEY"

    # Save the master.key to a .env file
    echo "RAILS_MASTER_KEY=$MASTER_KEY" > .env

    Rails g scaffold post title body:text

    # Build and run the containers
    docker-compose up --build
  EOF

  private_ip = "10.0.1.18"

  tags = {
    Name = "Rail-Docker"
  }
}
