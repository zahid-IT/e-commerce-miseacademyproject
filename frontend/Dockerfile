# Build stage
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json ./

# Fix AJV issue + clean install
RUN rm -rf node_modules package-lock.json && \
    npm cache clean --force && \
    npm install ajv@8 ajv-keywords@5 --save-exact && \
    npm install --legacy-peer-deps --no-audit --no-fund

COPY . .

RUN npm run build

# Production stage
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN rm -rf /usr/share/nginx/html/*

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
