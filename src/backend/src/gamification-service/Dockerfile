# Builder stage for compiling TypeScript code
# Requirement: System Architecture - Microservices architecture with container deployment
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files for dependency installation
# Using package.json from gamification-service
COPY package*.json ./

# Install all dependencies including devDependencies
# Requirement: Gamification System - Points and achievements for scalable deployment
RUN npm ci

# Copy source code and TypeScript config
COPY . .

# Build TypeScript code
# Using build script from package.json
RUN npm run build

# Production stage with minimal footprint
# Requirement: System Architecture - Core Components with microservices architecture
FROM node:20-alpine AS production

# Set working directory
WORKDIR /usr/src/app

# Copy package files for production install
COPY package*.json ./

# Install only production dependencies
# Requirement: Gamification System - Containerization for scalable deployment
RUN npm ci --only=production

# Copy built artifacts from builder stage
COPY --from=builder /usr/src/app/dist ./dist

# Set production environment
ENV NODE_ENV=production

# Expose service port
# Port 3000 as defined in app.ts
EXPOSE 3000

# Define healthcheck
# Requirement: Core Components - Core Services with microservices architecture
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Set user to non-root for security
USER node

# Start the service
# Using start script from package.json that runs dist/app.js
CMD ["npm", "start"]

# Human Tasks:
# 1. Configure MongoDB connection string in environment variables
# 2. Set up CORS configuration for production environment
# 3. Configure rate limiting and request throttling
# 4. Set up monitoring and alerting for service health
# 5. Configure logging infrastructure in production
# 6. Set up proper network security groups and firewall rules
# 7. Configure container resource limits and scaling policies
# 8. Set up secrets management for sensitive configuration