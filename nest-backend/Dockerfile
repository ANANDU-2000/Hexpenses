# Debian slim (not Alpine): Prisma's linux-musl engine needs libssl.so.1.1 which Alpine 3.17+ no longer ships in a compatible way.
FROM node:20-bookworm-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate && npm run build

FROM node:20-bookworm-slim
WORKDIR /app
RUN apt-get update && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma
EXPOSE 4000
ENV NODE_ENV=production
# nest build emits src under dist/ when tsconfig includes prisma/scripts (rootDir = .)
CMD ["node", "dist/src/main.js"]
