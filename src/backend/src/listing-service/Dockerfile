# Build stage for TypeScript compilation
# Requirement: 6.3 Containerization/Docker Configuration - Multi-stage builds for optimized images
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install all dependencies including devDependencies
# Requirement: Core Components - Node.js with TypeScript for type safety
RUN npm install

# Copy source code
COPY . .

# Build TypeScript code
RUN npm run build

# Remove devDependencies to reduce image size
RUN npm prune --production

# Production runtime stage
# Requirement: 6.3 Containerization/Docker Configuration - Minimal production images
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy built JavaScript files from builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules

# Set environment to production
# Requirement: Core Components - Production environment configuration
ENV NODE_ENV=production

# Create non-root user for security
# Requirement: Security - Secure container configuration with minimal attack surface
RUN addgroup -g 1001 founditure && \
    adduser -S -u 1001 -G founditure founditure && \
    chown -R founditure:founditure /usr/src/app

# Switch to non-root user
USER founditure

# Configure health check
# Requirement: Core Components - Container health monitoring
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1

# Expose API port
EXPOSE 3000

# Start application
CMD ["node", "dist/index.js"]