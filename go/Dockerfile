# Build stage
FROM golang:1.24-alpine AS builder
WORKDIR /src

# Pre-fetch dependencies for reproducible builds.
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o server .

# Tiny final image
FROM scratch
COPY --from=builder /src/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
