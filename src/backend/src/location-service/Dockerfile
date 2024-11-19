# ----------------------------------------
# Build Stage
# Requirements addressed:
# - Containerization (2.2.1 Core Components/Technology Stack)
# - Scalability (2.2.1 Core Components/Scaling Strategy)
# ----------------------------------------
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /usr/src/app

# Copy package files for dependency installation
COPY package*.json ./

# Install all dependencies including devDependencies
RUN npm ci

# Copy TypeScript source code and config files
COPY tsconfig.json ./
COPY src ./src

# Build TypeScript to JavaScript
RUN npm run build

# ----------------------------------------
# Production Stage
# Requirements addressed:
# - Security (5.2 Data Security)
# - Containerization (2.2.1 Core Components/Technology Stack)
# ----------------------------------------
FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files for production
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    # Clean npm cache to reduce image size
    npm cache clean --force

# Copy compiled JavaScript from build stage
COPY --from=builder /usr/src/app/dist ./dist

# Set secure user permissions
# Requirements addressed:
# - Security (5.2 Data Security)
RUN chown -R node:node /usr/src/app && \
    chmod -R 755 /usr/src/app

# Switch to non-root user for security
USER node

# Configure environment variables
ENV NODE_ENV=production \
    PORT=3000

# Expose service port
EXPOSE 3000

# Set startup command
CMD ["node", "dist/app.js"]