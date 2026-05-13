# Build stage
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./

# Clean dependencies
RUN rm -rf node_modules package-lock.json && \
    npm cache clean --force

# Install compatible AJV versions
RUN npm install ajv@6.12.6 ajv-keywords@3.5.2 --save-exact

# Install app dependencies
RUN npm install --legacy-peer-deps

COPY . .

# Disable CI warnings as build failures
ENV CI=false

RUN npm run build

# Production stage
FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN rm -rf /usr/share/nginx/html/*

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
