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



ARG NODE_NAME
ENV NODE_NAME=${NODE_NAME}

RUN git clone https://github.com/boyzwj/m1x.git
WORKDIR m1x


# set build ENV
ENV MIX_ENV=prod


# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

RUN cd assets && npm install
RUN mix assets.deploy
RUN mix release  --overwrite