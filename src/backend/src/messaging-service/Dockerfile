# Build stage
# Requirement: 2.2.1 Core Components/Messaging Service - Multi-stage build for optimized deployment
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies including dev dependencies for build
# Requirement: 2.2.1 Core Components/Messaging Service - Dependency management
RUN npm ci

# Copy source code and config files
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript application
RUN npm run build

# Production stage
# Requirement: 2.2.1 Core Components/Messaging Service - Optimized production container
FROM node:20-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create non-root user for security
# Requirement: 5.3 Security Requirements - Container security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy built JavaScript files from builder stage
COPY --from=builder /usr/src/app/dist ./dist

# Create log directory and set permissions
# Requirement: 2.4.1 System Monitoring - Log management
RUN mkdir -p /var/log/messaging-service && \
    chown -R appuser:appgroup /var/log/messaging-service

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3004

# Switch to non-root user
USER appuser

# Expose WebSocket and HTTP port
# Requirement: 2.2.1 Core Components/Messaging Service - Network configuration
EXPOSE 3004

# Configure health check
# Requirement: 2.4.1 System Monitoring - Container health monitoring
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3004/health || exit 1

# Set up volume mounts for logs
# Requirement: 2.4.1 System Monitoring - Persistent logging
VOLUME ["/var/log/messaging-service"]

# Start the messaging service
# Requirement: 1.2 System Overview/Core Features - Real-time messaging
CMD ["node", "dist/index.js"]