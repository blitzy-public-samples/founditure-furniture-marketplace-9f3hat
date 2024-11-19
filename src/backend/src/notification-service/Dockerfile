# Builder stage for compiling TypeScript code
# Requirement: 6.3 Containerization/Docker Configuration - Multi-stage builds for optimized production images
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files for dependency installation
COPY package*.json ./

# Install all dependencies including devDependencies
# npm v9.x is included in node:20-alpine
RUN npm ci

# Copy TypeScript source code and config files
COPY tsconfig*.json ./
COPY src/ ./src/

# Build TypeScript code to JavaScript
RUN npm run build

# Remove development dependencies
RUN npm prune --production

# Production stage with minimal footprint
# Requirement: 6.3 Containerization/Docker Configuration - Optimized production images
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files for production
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production

# Copy built JavaScript files from builder stage
COPY --from=builder /usr/src/app/dist ./dist

# Create non-root user and set ownership
# Requirement: 5.2 Data Security - Secure container configuration with non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 -G nodejs && \
    chown -R nodejs:nodejs /usr/src/app

# Switch to non-root user
USER nodejs:nodejs

# Set production environment variables
# Requirement: 2.4.1 System Monitoring - Container configuration supporting logging
ENV NODE_ENV=production \
    PORT=3000 \
    NODE_OPTIONS="--max-old-space-size=2048" \
    TZ=UTC

# Expose service port
EXPOSE 3000

# Configure health check
# Requirement: 2.4.1 System Monitoring - Container health monitoring
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start notification service
# Requirement: 1.3 Scope/Core Features - Push notification system
CMD ["node", "dist/app.js"]