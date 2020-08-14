FROM elixir:1.10.0-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base yarn git python

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
COPY assets/yarn.lock assets/yarn.lock ./assets/
RUN cd assets && yarn install --no-progress --frozen-lockfile && cd ..

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# Build the run container
FROM ubuntu:latest AS app

# Install packages, get texlive
RUN apt-get update && apt-get upgrade --yes
RUN apt-get install wget curl make openssl ncurses-libs --yes

# Install the TeX Live distro
RUN apt-get install --yes texlive-xetex

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/newton ./

ENV HOME=/app

CMD ["bin/newton", "start"]
