defmodule ExAirtable.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_airtable,
      name: "ExAirtable",
      description: description(),
      version: "0.2.4",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
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
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/exploration/ex_airtable"}
    ]
  end
end
