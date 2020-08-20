# Newton

## Production Deployment

### Building

*Note: you may skip this if you can and plan on using the pre-compiled
images from DockerHub.*

Build the container

    make docker-build

This will create a container named `ashton314/newton`.

### Deploying

Fire up the database

    docker-compose up -d db

That should create the database container with a persistent volume
attached to it. (This means that you can stop the database and restart
it and all your data will still be there. For more information see the
`docker volume` command.)

If you need to run migrations, run this command next:

    docker-compose run app bin/newton eval "Newton.Release.migrate"

That will run all the migrations to ensure that the database is
up-to-date.

Finally, start the app:

    docker-compose up -d

## Development

To start your Phoenix server:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
