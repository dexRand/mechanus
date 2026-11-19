# syntax=docker/dockerfile:1
FROM debian:bookworm-slim

# Bump this to update OpenCode, then rebuild: docker compose build --no-cache
ARG OPENCODE_VERSION=2.2.7

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates git jq bash \
 && rm -rf /var/lib/apt/lists/*

# Install OpenCode 1.x first, then upgrade --major to OpenCode 2.
RUN curl -fsSL https://opencode.ai/install | bash
ENV PATH="/root/.opencode/bin:${PATH}"
RUN opencode upgrade --major "${OPENCODE_VERSION}"

# Verify the pinned version.
RUN opencode --version

# MECHANUS config + agents + scripts (source of truth lives in this repo).
WORKDIR /mechanus
COPY opencode.json ./
COPY agents/ ./agents/
COPY bin/ ./bin/
COPY AGENTS.md ./

# Workspace: mount your project repos here.
RUN mkdir -p /workspace

# Entrypoint injects provider API keys from env into the global config.
COPY docker/entrypoint.sh /usr/local/bin/mechanus-entrypoint
RUN chmod +x /usr/local/bin/mechanus-entrypoint
ENTRYPOINT ["mechanus-entrypoint"]

EXPOSE 4096

# Default: web UI + API server (OpenCode 2's `serve`).
CMD ["opencode", "serve", "--hostname", "0.0.0.0", "--port", "4096"]
