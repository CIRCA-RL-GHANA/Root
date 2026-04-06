# ── Build stage ────────────────────────────────────────────────────────────────
FROM node:18-alpine AS builder
WORKDIR /app

COPY package*.json tsconfig.json ./
RUN npm install

COPY src ./src
RUN npm run build

# ── Production stage ────────────────────────────────────────────────────────────
FROM node:18-alpine AS production
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/package*.json ./
COPY --from=builder /app/dist ./dist

# Install only production dependencies (none for this minimal app)
RUN npm install --omit=dev

EXPOSE 3000
CMD ["node", "dist/main.js"]
