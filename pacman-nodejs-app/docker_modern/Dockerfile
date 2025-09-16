FROM node:20-alpine

WORKDIR /usr/src/app

# Copy source repo from build context
COPY pacman/ .

# Force modern Mongo driver
RUN npm pkg set dependencies.mongodb="^3.7.4" \
 && npm pkg set dependencies.@opentelemetry/api="^1.9.0" \
 && npm pkg set dependencies.@opentelemetry/sdk-metrics="^1.21.0" \
 && npm pkg set dependencies.@opentelemetry/exporter-metrics-otlp-http="^0.49.1" \
 && npm pkg set dependencies.@opentelemetry/resources="^1.21.0" \
 && npm pkg set dependencies.@opentelemetry/semantic-conventions="^1.21.0" \
 && npm pkg set dependencies.@splunk/otel="^3.3.0"

# Install app dependencies
RUN npm install --omit=dev

EXPOSE 8080
CMD ["npm", "start"]

