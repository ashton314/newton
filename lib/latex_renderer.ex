defmodule LatexRenderer do
  require Logger

  @moduledoc """
  Render LaTeX easily.

  You will need LaTeX installed on your system.

  Add this to your application tree:

  ```elixir
  {DynamicSupervisor, strategy: :one_for_one, name: LatexRenderer.Supervisor}
  ```
  And this to your config:

  ```elixir
  config :newton, LatexRenderer, cache: "/tmp/latex_renderer/cache"
  ```

  And point that at a directory that the renderer can write to.
  """

  @filename_base "question_preview"

  @doc """
  Given a token (really, just the first 32 characters of the hash of
  the latex string) return the path to the file.
  """
  def retrieve_from_token(token, suffix \\ "pdf") do
    base_dir = Application.fetch_env!(:newton, LatexRenderer) |> Keyword.get(:cache)

    if token =~ ~r/^[a-z0-9]+$/ && suffix =~ ~r/^[a-z]+$/ do
      {:ok, Path.join([base_dir, token, "#{@filename_base}.#{suffix}"])}
    else
      {:error, :bad_token}
    end
  end

  @doc """
  Given a string, formats the LaTeX, and returns a Path to the
  formatted PDF file.
  """
  @spec format_string(str :: String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def format_string(str) do
    Logger.debug("format_string called; this is process #{inspect(self())}")

    with {:ok, tmp, token} <- create_tmp(str),
         file <- Path.join(tmp, "#{@filename_base}.tex"),
         :ok <- File.write(file, str) do
      Logger.debug("format_string finished; returning token #{token}")
      run_latex(file, token)
    else
      {:eexist, token} ->
        Logger.debug("Already exists, token #{token}")
        {:ok, token}

      err ->
        err
    end
  end

  def create_tmp(data) do
    # Ensure we have a directory
    base_dir = Application.fetch_env!(:latex_renderer, :cache)

    unless File.dir?(base_dir) do
      File.mkdir!(base_dir)
    end

    # Generate a new unique path
    name =
      :crypto.hash(:sha512, data)
      |> Base.hex_encode32(case: :lower, padding: false)
      |> String.to_charlist()
      |> Enum.take(32)
      |> to_string()

    full_name = Path.join(base_dir, name)

    with :ok <- File.mkdir(full_name) do
      {:ok, full_name, name}
    else
      {:error, :eexist} -> {:eexist, name}
      err -> err
    end
  end

  @doc """
  Run XeLaTeX on a file given the path. Returns `{:ok, "retrieval_token"}` on success.
  Return `{:error, "Reason"}` otherwise.
  """
  def run_latex(path, token) do
    {dir, file} = split_at_file(path)
    base_file = Path.basename(file, ".tex")
    Logger.debug("Running xelatex on #{path}")

    with {_logs, 0} <- System.cmd("xelatex", ["-halt-on-error", "-output-directory=#{dir}", path]) do
      # Cleanup
      for ext <- ~w(aux log out) do
        File.rm(Path.join(dir, "#{base_file}.#{ext}"))
      end

      {:ok, token}
    else
      {reason, err} when is_integer(err) ->
        Logger.error("Couldn't format #{path}: Exit status #{err}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def split_at_file(path) do
    {Path.dirname(path), Path.basename(path)}
  end
end
