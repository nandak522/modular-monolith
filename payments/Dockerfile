FROM golang:1.24 AS builder
ENV USER=appuser \
    UID=10001 \
    GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"
WORKDIR /app
COPY cmd /app/cmd/
COPY config /app/config/
COPY go.* .
COPY *.go .
RUN cd /app && \
    go mod download && \
    go build -ldflags="-s -w" -a -o server ./cmd/server

FROM ubuntu:24.04
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
ENV DEBIAN_FRONTEND=noninteractive \
    USER=appuser
WORKDIR /app
COPY --chown=${USER}:${USER} --from=builder /app/server .
COPY --chown=${USER}:${USER} --from=builder /app/config .
RUN chown -Rv ${USER}:${USER} /app
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends curl net-tools netcat-openbsd dnsutils && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
USER ${USER}:${USER}
CMD ["/app/server", "-config=/app/local.yaml"]
