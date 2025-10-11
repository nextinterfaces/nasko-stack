# syntax=docker/dockerfile:1
FROM oven/bun:1.1-alpine

WORKDIR /app

# Install deps first for better caching
COPY package.json bun.lockb* ./
RUN bun install --production --frozen-lockfile || bun install --production

# Copy source
COPY . .

ENV PORT=8080
EXPOSE 8080

CMD ["bun", "run", "src/index.ts"]
