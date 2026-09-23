FROM node:22-alpine

WORKDIR /app

# Install native dependencies for sharp if required on alpine
RUN apk add --no-cache vips-dev build-base

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

CMD ["node", "src/server.js"]

