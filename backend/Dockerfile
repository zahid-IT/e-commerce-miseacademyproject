FROM node:18-alpine AS builder

WORKDIR /app

# Install MongoDB tools for backups
RUN apk add --no-cache mongodb-tools

COPY package*.json ./
COPY pnpm-lock.yaml yarn.lock* ./

RUN npm ci --only=production

COPY . .

# Create backup directory
RUN mkdir -p /backup && chown -R node:node /backup

FROM node:18-alpine

RUN apk add --no-cache dumb-init mongodb-tools curl

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app ./
COPY --from=builder --chown=nodejs:nodejs /backup /backup

USER nodejs

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "server.js"]
