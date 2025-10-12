# syntax=docker/dockerfile:1
FROM oven/bun:1.1-alpine
WORKDIR /app
COPY package.json bun.lockb* ./
RUN bun install --production --frozen-lockfile || bun install --production
COPY . .
ENV PORT=8081
EXPOSE 8081
CMD ["bun", "run", "src/index.ts"]
