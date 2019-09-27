# The version of Alpine to use for the final image
# This should match the version of Alpine that the `elixir:1.9.1-alpine` image uses
ARG ALPINE_VERSION=3.10

FROM elixir:1.9.1-alpine AS builder

# The following are build arguments used to change variable parts of the image
ARG APP_NAME
ARG APP_VSN
ARG MIX_ENV=releases

ENV APP_NAME=${APP_NAME} \
    APP_VSN=${APP_VSN} \
    MIX_ENV=${MIX_ENV}

# By convention, /opt is typically used for applications
WORKDIR /opt/app

# This step installs all the build tools we'll need
RUN apk update && \
    apk upgrade --no-cache && \
    mix local.rebar --force && \
    mix local.hex --force

# This copies our app source code into the build container
COPY . .

RUN mix do deps.get, deps.compile, compile

RUN mkdir -p /opt/built && \
    mix release && \
    cp -r _build/${MIX_ENV}/rel/${APP_NAME}/* /opt/built

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:${ALPINE_VERSION}

ARG APP_NAME

RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache bash openssl-dev inotify-tools

ENV REPLACE_OS_VARS=true \
    APP_NAME=${APP_NAME}

WORKDIR /opt/app

COPY --from=builder /opt/built .

CMD trap 'exit' INT; /opt/app/bin/${APP_NAME} start
