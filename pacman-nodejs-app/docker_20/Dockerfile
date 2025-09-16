FROM node:20-alpine

MAINTAINER Ivan Font <ifont@redhat.com>

# Install git to clone the app
RUN apk add --no-cache git

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Clone game source code
RUN git clone https://github.com/font/pacman.git .

# modern MongoDB
RUN npm pkg set dependencies.mongodb="^3.7.4"

# Install app dependencies
RUN npm install

# Expose port 8080
EXPOSE 8080

# Run container
CMD ["npm", "start"]
