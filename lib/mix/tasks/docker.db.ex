defmodule Mix.Tasks.Docker.Db do
  use Mix.Task

  @project_name "Newton"
  @project_sname "newton"

  @shortdoc "Start/stop the docker Postgres container for development"

  @moduledoc """
  Fire up a postgres database for #{@project_name}, named #{@project_sname} in Docker.

  ## Usage:

      $ mix docker.db start
      $ mix docker.db stop
  """

  @impl Mix.Task
  def run(["start"]) do
    volume = "#{@project_sname}_volume"

    Mix.shell().info("Starting container named #{@project_sname} with volume #{volume}...")

    System.cmd("docker", [
      "run",
      "--rm",
      "-d",
      "-e",
      "POSTGRES_PASSWORD=postgres",
      "-p",
      "5433:5432",
      "--mount",
      "type=volume,src=#{volume},dst=/var/lib/postgresql/data",
      "--name",
      @project_sname,
      "postgres"
    ])

    Mix.shell().info("done.")
  end

  @impl Mix.Task
  def run(["stop"]) do
    System.cmd("docker", ["stop", @project_sname])
    Mix.shell().info("Container #{@project_sname} stopped")
  end
end
