FROM ubuntu

# Install packages, get texlive
RUN apt-get update && apt-get upgrade --yes
RUN apt-get install wget curl make --yes

# Install tzdata non-interactively
RUN ln -fs /usr/share/zoneinfo/America/Denver /etc/localtime
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata

# Install the TeX Live distro
RUN apt-get install --yes texlive-xetex

# Ok, now install me some elixir!
RUN apt-get install gnupg --yes
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get install esl-erlang elixir --yes
RUN apt-get install git build-essential erlang-dev erlang-parsetools --yes

# 
RUN mkdir /app
WORKDIR /app

ENV MIX_ENV=prod

COPY mix.exs /app/
COPY mix.lock /app/

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

COPY assets /app/assets/
COPY config /app/config/
COPY config/prod.secret.exs /app/config/prod.secret.exs
COPY lib /app/lib/
COPY priv /app/priv/
COPY test /app/test/

CMD mix ecto.create && mix ecto.migrate && mix phx.server
