# OpenSpace Frontend Dockerfile
# Multi-stage build for the React dashboard UI

# Build stage
FROM node:20-alpine AS builder

# Install dependencies
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build arguments for environment variables
ARG VITE_API_PROXY_TARGET=http://localhost:7788
ARG VITE_PORT=3789
ARG VITE_HOST=0.0.0.0

# Set environment variables for build
ENV VITE_API_PROXY_TARGET=${VITE_API_PROXY_TARGET}
ENV VITE_PORT=${VITE_PORT}
ENV VITE_HOST=${VITE_HOST}

# Build the application
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Install curl for health check
RUN apk add --no-cache curl

# Copy nginx configuration
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Create non-root user
RUN addgroup -g 1000 -S openspace && \
    adduser -u 1000 -S openspace -G openspace && \
    chown -R openspace:openspace /usr/share/nginx/html && \
    chown -R openspace:openspace /var/cache/nginx && \
    chown -R openspace:openspace /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R openspace:openspace /var/run/nginx.pid

# Expose port
EXPOSE 3789

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3789/ || exit 1

# Run nginx
CMD ["nginx", "-g", "daemon off;"]
