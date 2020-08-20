FROM elixir:1.10.0-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base yarn git python npm

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# build assets
RUN npm install --global webpack
COPY assets/yarn.lock assets/yarn.lock ./assets/
RUN cd assets && yarn install --no-progress --frozen-lockfile && cd ..

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY lib lib
RUN mix do compile, release

################################
# Build Application Containers #
################################

FROM alpine:3.9 AS app
RUN apk add --no-cache openssl ncurses-libs texlive-xetex

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/newton ./

ENV HOME=/app

# bin/newton eval "Newton.Release.migrate"
CMD bin/newton start
