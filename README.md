# Newton

Newton is designed as a successor to an earlier project I constructed
for the BYU Math Department. It's been a few years and I've learned a
few things since my initial foray into freelance application
development, so hopefully getting started with Newton won't be too
bumpy for you.

Newton serves as a repository for math problems written in LaTeX. A
user of this program logs in, and can add, edit or remove questions in
the question corpus. Newton will generate renders of the questions
on-the-fly for the user so they can quickly see the effects of their
edits. Users can also assemble the questions into tests. These tests
persist so that they can easily be ammended.

## Feature Roadmap

There are several features missing from Newton that the old system
included. Some of the not-quite-there features include:

 - Comments on questions
 - Image resources for questions
 - Statistics on test results
 - Export and backup facilities

Once these features are added, we will have exceeded parity with the
old system.

## Technical Overview

Newton is programmed in [Elixir](https://elixir-lang.org) using the
[Phoenix Framework](https://www.phoenixframework.org/), with [Phoenix
LiveView](https://github.com/phoenixframework/phoenix_live_view) for
the frontend. Newton is tuned for a Postgres database—you *will*
encounter problems if you try using MySQL.

The live render feature is the most technologically involved. Roughly
what happens is this:

 1. The user makes an edit to the question.
 2. The `NewtonWeb.QuestionLive.FormComponent` module receives a
    debounced edit event from the `textarea` input field.
 3. The `FormComponent` calls a function inside the `LatexRenderer`
    module, which renders the question template into a string, and
    then fires of an asynchronous task that renders the PDF. The main
    thread returns to handle the UI as normal.
 4. The asynchronous task, supervised by the
    `LatexRendering.Supervisor` supervisor (sorry—lots of supervision
    going on here) runs and invokes a callback the `FormComponent`
    gave it.
 5. The callback sends a message to the LiveView process with either
    the render error or the location on the file system where the
    temporary render is cached.
 6. The LiveView displays the error/image.

Now, you might wonder what happens to all the rendered PDFs—those can
quickly start to take up a lot of space! At the start of the
application, a GenServer named `Newton.GarbageCollector` starts up
and, every 300 seconds (configurable), deletes renders older than a
minute (also configurable).

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

 - Make sure the database is setup; if you have
   [Docker](https://docker.com) installed, you should be able to run
   `mix docker.db start`, which will start a development-ready
   Postgres container on your system
 - Setup the project with `mix setup`
 - Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
