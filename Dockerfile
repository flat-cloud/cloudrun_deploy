FROM node:18-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

# Use the PORT environment variable provided by Cloud Run
ENV PORT=8080
EXPOSE 8080

CMD ["node", "index.js"]
