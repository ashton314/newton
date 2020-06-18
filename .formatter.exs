[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  subdirectories: ["priv/*/migrations"]
]
