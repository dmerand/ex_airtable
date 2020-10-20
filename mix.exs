defmodule ExAirtable.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_airtable,
      name: "ExAirtable",
      description: description(),
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url: "https://github.com/exploration/ex_airtable"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    An Airtable API interface that optionally provides a rate-limiting server and a local cache.
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:gen_stage, "~> 1.0"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"}
    ]
  end
end
