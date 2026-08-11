FROM golang:1.26
# The build stamps the binary from the checkout's git state, and a .git that is
# present but unreadable makes that stamp fail the whole build with
# "error obtaining VCS status: exit status 128" instead of being skipped. Turn
# the stamp off so no git state can reach the toolchain.
ENV GOFLAGS=-buildvcs=false
RUN apt-get update && apt-get install -y --no-install-recommends git tmux asciinema && rm -rf /var/lib/apt/lists/*
RUN command -v tmux && command -v asciinema
WORKDIR /app
COPY repo/ .
RUN n=0; until go mod download; do n=$((n+1)); if [ $n -ge 3 ]; then exit 1; fi; echo "dependency install failed (attempt $n/3), retrying…" >&2; sleep $((n*15)); done
# The compile has to fail the build when it fails. It was chained into a
# `|| true` that also swallowed it, so an image whose tree does not build came
# out green and the failure surfaced later as an unexplained verifier error.
RUN go build ./...
# go vet stays advisory: it reports style problems that are not build failures.
RUN go vet ./... >/dev/null 2>&1 || true
CMD ["sh", "-c", "go test ./..."]
RUN mkdir -p /installed-agent
RUN command -v patch >/dev/null 2>&1 || ( (apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*) 2>/dev/null || apk add --no-cache patch 2>/dev/null || yum install -y patch 2>/dev/null || true )
