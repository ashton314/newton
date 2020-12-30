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
    base_dir = Application.fetch_env!(:newton, :latex_cache)

    if token =~ ~r/^[a-z0-9-]+$/ && suffix =~ ~r/^[a-z]+$/ do
      {:ok, Path.join([base_dir, token, "#{@filename_base}.#{suffix}"])}
    else
      {:error, :bad_token}
    end
  end

  @spec image_string_async(
          str :: String.t(),
          callback :: ({:ok, String.t()} | {:error, String.t()} -> any()),
          opts :: Keyword.t()
        ) :: Supervisor.on_start()
  def image_string_async(str, callback, opts \\ []) do
    DynamicSupervisor.start_child(
      LatexRendering.Supervisor,
      {Task,
       fn ->
         # Logger.debug("[LatexRenderer] spawned render task #{inspect(self())}")
         callback.(format_image(str, opts))
       end}
    )
  end

  @spec format_string_async(
          str :: String.t(),
          callback :: ({:ok, String.t()} | {:error, String.t()} -> any())
        ) :: Supervisor.on_start()
  def format_string_async(str, callback) do
    DynamicSupervisor.start_child(
      LatexRendering.Supervisor,
      {Task,
       fn ->
         # Logger.debug("[LatexRenderer] spawned render task #{inspect(self())}")
         callback.(format_string(str))
       end}
    )
  end

  @doc """
  Given a string, formats the LaTeX, and returns a Path to the
  formatted png file.
  """
  @spec format_image(str :: String.t(), opts :: Keyword.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def format_image(str, opts \\ []) do
    # Logger.debug("format_opts called; this is process #{inspect(self())}")
    base_dir = Application.fetch_env!(:newton, :latex_cache)

    with {:ok, token} <- format_string(str, opts),
         :ok <- make_image(Path.join([base_dir, token, "#{@filename_base}.pdf"])) do
      # Logger.debug("Successfully built: #{token}")
      {:ok, token}
    else
      {:eexist, token} ->
        # Logger.debug("Already exists, token #{token}")
        {:ok, token}

      err ->
        err
    end
  end

  @doc """
  Given a string, formats the LaTeX, and returns a Path to the
  formatted PDF file.
  """
  @spec format_string(str :: String.t(), opts :: Keyword.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def format_string(str, opts \\ []) do
    # Logger.debug("format_string called; this is process #{inspect(self())}")

    with {:ok, tmp, token} <- create_tmp(str, Keyword.get(opts, :dir)),
         file <- Path.join(tmp, "#{@filename_base}.tex"),
         :ok <- File.write(file, str) do
      # Logger.debug("format_string finished; returning token #{token}")
      run_latex(file, token)
    else
      {:eexist, token} ->
        # Logger.debug("Already exists, token #{token}")
        {:ok, token}

      err ->
        err
    end
  end

  def create_tmp(data, dirname \\ nil) do
    # Ensure we have a directory
    base_dir = Application.fetch_env!(:newton, :latex_cache)

    unless File.dir?(base_dir) do
      File.mkdir_p!(base_dir)
    end

    # Generate a new unique path
    name =
      if is_nil(dirname) do
        :crypto.hash(:sha512, data)
        |> Base.hex_encode32(case: :lower, padding: false)
        |> String.to_charlist()
        |> Enum.take(32)
        |> to_string()
      else
        dirname
      end

    full_name = Path.join(base_dir, name)

    with :ok <- File.mkdir(full_name) do
      {:ok, full_name, name}
    else
      {:error, :eexist} -> {:eexist, name}
      err -> err
    end
  end

  @doc """
  Runs the convert command on the path to turn the PDF into a png
  """
  @spec make_image(String.t()) :: :ok | {:error, String.t()}
  if Mix.env() == :test do
    def make_image(path) when is_binary(path), do: :ok
  end

  def make_image(path) do
    # Logger.debug("Converting #{inspect(path)} into a PNG")
    {dir, file} = split_at_file(path)
    base_file = Path.basename(file, ".pdf")
    # Logger.debug("Converting #{base_file} for question #{dir}")

    # "-density",
    # "3000x3000",
    # "#{dir}/#{base_file}.pdf",
    # "-quality",
    # "150",
    # "-resize",
    # "3000x3000",
    # "-fuzz",
    # "40%",
    # "-fill",
    # "white",
    # "-opaque",
    # "black",
    # "#{dir}/#{base_file}.png"

    with {:exists?, false} <- {:exists?, File.exists?("#{dir}/#{base_file}.png")},
         {_logs, 0} <-
           System.cmd("convert", [
             # Dev options (for faster render)
             "-density",
             "1500x1500",
             "#{dir}/#{base_file}.pdf",
             "-quality",
             "90",
             "-resize",
             "1500x1500",

             # "-density",
             # "3000x3000",
             # "#{dir}/#{base_file}.pdf",
             # "-quality",
             # "150",
             # "-resize",
             # "3000x3000",
             # End prod arguments

             "-fuzz",
             "40%",
             "-fill",
             "white",
             "-opaque",
             "black",
             "#{dir}/#{base_file}.png"
           ]) do
      :ok
    else
      {:exists?, true} ->
        # Logger.debug("Bypassing conversion for #{dir}/#{base_file}.png because it's already there")

        :ok

      {reason, err} when is_integer(err) ->
        Logger.error("Couldn't convert #{path} into a png: Exit #{err} with message #{inspect(reason)}")

        {:error, reason}
    end
  end

  @doc """
  Run XeLaTeX on a file given the path. Returns `{:ok, "retrieval_token"}` on success.
  Return `{:error, "Reason"}` otherwise.
  """
  def run_latex(path, token) do
    {dir, file} = split_at_file(path)
    base_file = Path.basename(file, ".tex")
    # Logger.debug("Running xelatex on #{path}")

    latex_program = Application.fetch_env!(:newton, :latex_program)

    with {_logs, 0} <-
           System.cmd(latex_program, ["-halt-on-error", "-output-directory=#{dir}", path]) do
      # Cleanup
      for ext <- ~w(aux log out) do
        File.rm(Path.join(dir, "#{base_file}.#{ext}"))
      end

      {:ok, token}
    else
      {reason, err} when is_integer(err) ->
        Logger.error("Couldn't format #{path}: Exit status #{err}: #{inspect(reason)}")
        # Remove directory of failed render
        File.rm_rf(dir)
        {:error, reason}
    end
  end

  def split_at_file(path) do
    {Path.dirname(path), Path.basename(path)}
  end
end
