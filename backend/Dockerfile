# Stage 1: base Node image
FROM node:20-alpine

WORKDIR /app

# install dependencies first (better caching)
COPY package*.json ./

RUN npm ci --legacy-peer-deps || npm install --legacy-peer-deps

# copy source code
COPY . .

# expose backend port
EXPOSE 3000

# start server
CMD ["node", "server.js"]
