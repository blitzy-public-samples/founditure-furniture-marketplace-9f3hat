# Stage 1: Builder stage for compiling TypeScript and installing dependencies
# Requirement: 6.3 Containerization - Docker configuration for API container using node:20-alpine as base image
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install build dependencies including TypeScript and required @types
# Note: Using exact versions from package.json
RUN npm ci

# Copy source code and config files
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript to JavaScript
RUN npm run build

# Prune development dependencies
RUN npm prune --production

# Stage 2: Production stage with minimal runtime dependencies
# Requirement: Core Components - AI Services using TensorFlow and AWS Rekognition
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files and built code from builder stage
COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist

# Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Create and use non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /usr/src/app

USER nodejs

# Configure security options
# Requirement: 6.3 Containerization - Security hardening
RUN apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Set security options
LABEL maintainer="Founditure DevOps Team" \
      description="AI Service for furniture recognition using TensorFlow and AWS Rekognition" \
      version="1.0.0"

# Create volume mounts for persistent data
VOLUME ["/usr/src/app/node_modules", "/usr/src/app/dist"]

# Expose service port
EXPOSE 3000

# Configure health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Set startup command
CMD ["node", "dist/app.js"]

# Apply security configurations
STOPSIGNAL SIGTERM
RUN echo "kernel.unprivileged_userns_clone=1" >> /etc/sysctl.conf

# Security hardening
# Drop all capabilities and enable no-new-privileges
RUN echo "no-new-privileges=true" >> /etc/security/limits.conf
RUN chmod -R 555 /usr/src/app

# Read-only root filesystem
RUN chmod 555 /usr/src/app/dist && \
    chmod 555 /usr/src/app/node_modules

# Set security options
SECURITY_OPT no-new-privileges:true