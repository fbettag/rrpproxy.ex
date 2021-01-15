defmodule RRPproxy.Mixfile do
  use Mix.Project

  @project_url "https://github.com/fbettag/rrpproxy.ex"

  def project do
    [
      app: :rrpproxy,
      version: "0.1.6",
      elixir: "~> 1.4",
      source_url: @project_url,
      homepage_url: @project_url,
      name: "RRPproxy.net API",
      description: "This package implements the RRPproxy.net API for registering domains",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:poison, "~> 4.0.1"},
      {:httpoison, "~> 1.7"},
      {:ecto, "~> 3.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, github: "rrrene/credo", only: [:dev, :test]},
      {:doctor, "~> 0.17.0", only: :dev},
      {:git_hooks, "~> 0.4.0", only: [:test, :dev], runtime: false}
    ]
  end

  defp package do
    [
      name: "rrpproxy",
      maintainers: ["Franz Bettag"],
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url}
    ]
  end

  defp aliases do
    [
      credo: "credo -a --strict"
    ]
  end
end
