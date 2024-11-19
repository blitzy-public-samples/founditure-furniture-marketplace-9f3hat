# Requirement: 6.3 CONTAINERIZATION/Container Specifications - Multi-stage build for minimal footprint
# Builder stage for compiling TypeScript and installing dependencies
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install build dependencies
# Requirement: 5.3 SECURITY PROTOCOLS/5.3.2 Security Controls - Minimal attack surface
RUN npm ci

# Copy source code
COPY . .

# Build TypeScript to JavaScript
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Requirement: 6.3 CONTAINERIZATION/Container Specifications - Production stage with minimal footprint
# Production stage
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy built artifacts and dependencies from builder stage
COPY --from=builder /usr/src/app/dist ./dist
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/package*.json ./

# Requirement: 5.3 SECURITY PROTOCOLS/5.3.2 Security Controls - Non-root user for security
# Create non-root user and set permissions
RUN addgroup -S appgroup && \
    adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /usr/src/app

# Switch to non-root user
USER appuser

# Expose application port
EXPOSE 3000

# Set production environment
ENV NODE_ENV=production \
    PORT=3000

# Requirement: 5.3 SECURITY PROTOCOLS/5.3.2 Security Controls - Health monitoring
# Configure health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Requirement: 5.1 AUTHENTICATION AND AUTHORIZATION/5.1.1 Authentication Methods
# Define entry point
ENTRYPOINT ["node", "dist/app.js"]