# Build stage
# Requirement: 6.3 Containerization/Docker Configuration - Multi-stage build optimization
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files for dependency installation
COPY package*.json ./

# Install all dependencies including devDependencies
# Requirement: 2.4.1 System Monitoring - Component Details
RUN npm ci

# Copy source code and config files
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript code
RUN npm run build

# Run tests to verify build
RUN npm run test

# Remove devDependencies
RUN npm prune --production

# Production stage
# Requirement: A.3 Environment Configuration - Production environment container configuration
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Install production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy built JavaScript files from builder stage
COPY --from=builder /usr/src/app/dist ./dist

# Create non-root user for security
# Requirement: A.3 Environment Configuration - Security hardening
RUN addgroup -S founditure && \
    adduser -S -G founditure founditure && \
    chown -R founditure:founditure /usr/src/app

# Set proper file permissions
RUN chmod -R 550 /usr/src/app/dist && \
    chmod -R 550 /usr/src/app/node_modules && \
    chmod -R 770 /usr/src/app/logs

# Set production environment
ENV NODE_ENV=production

# Configure health check endpoint
# Requirement: 2.4.1 System Monitoring - Component Details
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Expose port for metrics and API
# Requirement: 2.4.1 System Monitoring - Cross-Cutting Concerns
EXPOSE 3000

# Switch to non-root user
USER founditure

# Set entry command
CMD ["node", "dist/app.js"]