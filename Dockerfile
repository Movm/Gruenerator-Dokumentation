# Multi-stage build for optimal image size
FROM node:18-alpine as builder

WORKDIR /app

# Copy package files first (better Docker layer caching)
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production --silent

# Copy source code
COPY . .

# Build the static site
RUN npm run build

# Production stage - minimal nginx image
FROM nginx:alpine

# Copy built files to nginx web root
COPY --from=builder /app/build /usr/share/nginx/html

# Copy minimal nginx configuration for Docusaurus routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Add non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
