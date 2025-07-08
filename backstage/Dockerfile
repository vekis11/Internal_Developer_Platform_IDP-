# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./
COPY packages/app/package.json ./packages/app/
COPY packages/backend/package.json ./packages/backend/
COPY packages/cli/package.json ./packages/cli/

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN yarn tsc
RUN yarn build

# Production stage
FROM node:18-alpine AS production

WORKDIR /app

# Copy built application
COPY --from=builder /app/packages/app/dist ./packages/app/dist
COPY --from=builder /app/packages/app/package.json ./packages/app/package.json
COPY --from=builder /app/packages/backend/dist ./packages/backend/dist
COPY --from=builder /app/packages/backend/package.json ./packages/backend/package.json
COPY --from=builder /app/packages/cli/dist ./packages/cli/dist
COPY --from=builder /app/packages/cli/package.json ./packages/cli/package.json

# Copy configuration files
COPY app-config.yaml ./
COPY app-config.production.yaml ./

# Install production dependencies
RUN yarn install --production --frozen-lockfile

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S backstage -u 1001

# Change ownership of the app directory
RUN chown -R backstage:nodejs /app
USER backstage

# Expose ports
EXPOSE 3000 7007

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:7007/healthcheck || exit 1

# Start the application
CMD ["yarn", "workspace", "backend", "start"] 