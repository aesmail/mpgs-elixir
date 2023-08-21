defmodule Mpgs.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :mpgs,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Mpgs.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.16.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
