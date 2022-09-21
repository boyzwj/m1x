FROM bitwalker/alpine-elixir:latest AS builder

# Install build dependencies
RUN apk update && \
    apk add --no-cache \
    bash \
    build-base \
    curl \
    git \
    libgcc \
    python3 \
    ca-certificates \
    gcc \
    g++ \
    rust \
    cargo \
    protoc

# Install Node.js
RUN apk add --update npm

# Prepare app dir
RUN mkdir /app
WORKDIR /app
ENV HOME=/app


ENV MIX_ENV=prod


# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY config config

RUN mix do deps.get, deps.compile

# copy source code
COPY rel rel
COPY lib lib
COPY priv priv
COPY assets assets



RUN cd assets && npm install
RUN mix assets.deploy
RUN mix release  --overwrite
