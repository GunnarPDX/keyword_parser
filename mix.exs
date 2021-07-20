defmodule Keywords.MixProject do
  use Mix.Project

  def project do
    [
      app: :keywords,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "keywords",
      source_url: "https://github.com/GunnarPDX/keyword_parser"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Keywords.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description() do
    """
    Parses keywords from strings.
    """
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/GunnarPDX/keyword_parser"}
    ]
  end
end
