defmodule Keywords.MixProject do
  use Mix.Project

  def project do
    [
      app: :keywords,
      version: "1.3.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      compilers: Mix.compilers(),
      rustler_crates: rustler_crates(),
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:rustler, "~> 0.29.0"}
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
      files: ~w(lib native .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/GunnarPDX/keyword_parser"}
    ]
  end

  defp rustler_crates do
    [
      keywords: [path: "native/parser", mode: if(Mix.env() == :prod, do: :release, else: :debug)]
    ]
  end
end
