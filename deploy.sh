#!/bin/bash

# Set your Docker Hub username
DOCKERHUB_USERNAME="randytuan098"  # Replace with your actual username

# Pull the latest code
git pull origin master

# Pull the latest Docker image
docker pull $DOCKERHUB_USERNAME/webnetflopt-php:latest

# Create a modified docker-compose file that uses the pre-built image
cat > docker-compose.deploy.yml << EOL
version: '3.8'
services:
  nginx:
    image: nginx:1.17.4-alpine
    ports:
      - 8888:80
    depends_on:
      - php
      - db
    volumes:
      - .:/application
      - ./docker/config/default.conf:/etc/nginx/conf.d/default.conf

  php:
    image: ${DOCKERHUB_USERNAME}/webnetflopt-php:latest
    volumes:
      - .:/application
      - ./docker/php/custom.ini:/usr/local/etc/php/conf.d/custom.ini
    depends_on:
      - db
      - redis
    environment:
      - DB_PORT=3306
      - DB_HOST=db
      - DB_USERNAME=root
      - DB_PASS=secret
      - DB_NAME=app_db

  db:
    image: mariadb:10.5.8
    container_name: db
    ports:
      - "3307:3306"
    volumes:
      - db_data:/var/lib/mysql
    environment:
      - MYSQL_DATABASE=app_db
      - MYSQL_ROOT_PASSWORD=123456789
      - MYSQL_PASSWORD=123456789

  redis:
    image: redis:5.0.6-alpine
    ports:
      - "6382:6379"

  phpmyadmin:
    image: phpmyadmin
    ports:
      - 8082:80
    
volumes:
  db_data:
EOL

# Stop current containers and start with the deployment version
docker-compose -f docker-compose.deploy.yml down
docker-compose -f docker-compose.deploy.yml up -d

# Run Laravel commands
docker-compose -f docker-compose.deploy.yml exec php php artisan migrate --force
docker-compose -f docker-compose.deploy.yml exec php php artisan optimize:clear
docker-compose -f docker-compose.deploy.yml exec php php artisan optimize

echo "Deployment completed successfully!"