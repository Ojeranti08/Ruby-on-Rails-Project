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

   # Set GEM_HOME and GEM_PATH
   echo 'export GEM_HOME=$HOME/.local/share/gem/ruby' >> ~/.bashrc
   echo 'export GEM_PATH=$GEM_HOME:/usr/share/ruby3.2-gems:/usr/share/gems:/usr/local/share/ruby3.2-gems:/usr/local/share/gems' >> ~/.bashrc

   # Add Ruby gems binary directory to PATH
   echo 'export PATH=$PATH:$GEM_HOME/bin' >> ~/.bashrc
   source ~/.bashrc 

   # Install Rails (without -y flag, as gem install doesn't accept it)
   sudo yum remove ruby -y
   sudo yum remove ruby-devel -y
   sudo yum -y install ruby
   sudo yum install ruby-devel -y

   # Install Rails
   sudo gem install rails -v 6.1.4
 
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

     gem 'Rails', '6.1.4' # Adjust the version based on my Rails application requirements

     group :development, :test do
     gem 'sqlite3', '1.4.2' # Use the appropriate database gem and version for development and testing
     end

     group :production do
     gem 'pg', '1.2.3' # Use the appropriate database gem and version for production (PostgreSQL)
     end 
    
   # Change directory to Ruby-on-Rails-Project
   cd /home/ec2-user/Ruby-on-Rails-Project
   
   # Change directory to rails-docker
   cd rails-docker

   # Remove files
    sudo rm -rf Gemfile \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config/database.yaml \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config/routes.rb \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/bin/docker-entrypoint
 
   # Move the files from Ruby-on-Rails-Project to the rails-docker directory
    mv /home/ec2-user/Ruby-on-rails-project/Dockerfile \
        /home/ec2-user/Ruby-on-rails-project/Gemfile \
        /home/ec2-user/Ruby-on-rails-project/docker-compose.yaml \
        /home/ec2-user/Ruby-on-rails-project/Dockerfile-PostgresSQL \
        
    mv /home/ec2-user/rails-docker/Ruby-on-rails-project/docker-entrypoint \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/bin

    mv /home/ec2-user/rails-docker/Ruby-on-rails-project/database.yaml \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config

    mv /home/ec2-user/rails-docker/Ruby-on-rails-project/routes.rb \
        /home/ec2-user/Ruby-on-rails-project/rails-docker/config

   # Change directory to Ruby-on-Rails-Project
   #cd /home/ec2-user/Ruby-on-Rails-Project

   # Generate a new secret key
   MASTER_KEY=$(Rails secret)

   # Create a new .env file with the new secret key
   echo "RAILS_MASTER_KEY=$MASTER_KEY" > .env

   # Move the .env file to the correct location (rails-docker)
   sudo mv .env /home/ec2-user/Ruby-on-Rails-Project/rails-docker/config

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
