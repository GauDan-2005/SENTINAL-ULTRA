FROM node:20-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# System libraries required by the Chromium that puppeteer downloads,
# plus tooling used by the Harbor build/agent tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git patch curl wget \
    fonts-liberation fonts-noto-color-emoji fonts-noto-cjk \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2 libatspi2.0-0 \
    libx11-6 libx11-xcb1 libxcb1 libxext6 libxi6 libxtst6 libglib2.0-0 libexpat1 \
    libxshmfence1 libxrender1 libxcursor1 libxss1 libgtk-3-0 libgdk-pixbuf2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY repo/ .

# Install the project dependencies (network is available at build time only).
# puppeteer 2.0.0 downloads its bundled Chromium during this step.
RUN npm install

# The outline feature depends on pdf-lib; the evaluation tests also import
# pdf-lib and run under nyc for coverage. These must be present in the image
# because there is no network at test time.
RUN npm install --no-save pdf-lib@^1.2.1 nyc@^15.1.0

CMD ["sh", "-c", "npm test"]

RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
RUN (command -v tmux >/dev/null 2>&1 && command -v asciinema >/dev/null 2>&1) || ( (apt-get update && apt-get install -y --no-install-recommends tmux asciinema && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache tmux asciinema 2>/dev/null || dnf install -y tmux asciinema 2>/dev/null || yum install -y tmux asciinema 2>/dev/null || true )
