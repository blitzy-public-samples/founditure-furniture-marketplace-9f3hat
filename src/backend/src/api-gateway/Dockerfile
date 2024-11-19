# Requirement: 2.1 High-Level Architecture/Component Details - API Gateway service configuration
# Builder stage for compiling TypeScript and installing dependencies
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with npm ci for consistent builds
# Requirement: 2.5 Security Architecture/2.5.1 Security Controls - Secure dependency installation
RUN npm ci

# Copy source code
COPY . .

# Build TypeScript application
RUN npm run build

# Prune development dependencies
RUN npm prune --production

# Requirement: 2.1 High-Level Architecture/Component Details - Production stage configuration
# Production stage with minimal footprint and security hardening
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Requirement: 2.5 Security Architecture/2.5.1 Security Controls - Non-root user configuration
# Create non-root user and group
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy built artifacts from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Requirement: 2.4.1 System Monitoring - Configure container for log output
# Create log directory with proper permissions
RUN mkdir -p /app/logs && \
    chown -R nodejs:nodejs /app/logs && \
    chmod 755 /app/logs

# Configure production environment
ENV NODE_ENV=production
ENV PORT=3000

# Expose service port
EXPOSE 3000

# Switch to non-root user context
USER nodejs

# Requirement: 2.4.1 System Monitoring - Health check configuration
# Configure HTTP health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Set entry command to run compiled app
CMD ["node", "dist/app.js"]