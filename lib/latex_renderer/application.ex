defmodule LatexRenderer.Application do
  use Application

  # This module is not being used!

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: LatexRenderer.RenderTaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: LatexRenderer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
