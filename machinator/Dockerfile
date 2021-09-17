FROM golang:1.17-bullseye as builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY main.go .
RUN CGO_ENABLED=0 go build -ldflags="-s"

# NB we use the bullseye-slim (instead of scratch) image so we can enter the container to execute bash etc.
FROM debian:bullseye-slim
COPY --from=builder /app/machinator .
EXPOSE 8000
ENTRYPOINT ["/machinator"]