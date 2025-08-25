FROM node:20.18.0-slim AS builder

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

COPY tsconfig.json next.config.mjs next-env.d.ts postcss.config.js drizzle.config.ts tailwind.config.ts ./
COPY src ./src
COPY public ./public

RUN mkdir -p /app/data
RUN yarn build

RUN yarn add --dev @vercel/ncc
RUN yarn ncc build ./src/lib/db/migrate.ts -o migrator

FROM node:20.18.0-slim

WORKDIR /app

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/static ./public/_next/static

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/data ./data

COPY drizzle ./drizzle
COPY --from=builder /app/migrator/build ./build
COPY --from=builder /app/migrator/index.js ./migrate.js

RUN mkdir /app/uploads

COPY sample.config.toml /config/config.toml
COPY entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh
CMD ["bash", "./entrypoint.sh"]
