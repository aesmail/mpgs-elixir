defmodule Mpgs.MixProject do
  use Mix.Project

  @version "2.0.0-rc.1"
  @source_url "https://github.com/aesmail/mpgs-elixir"

  def project do
    [
      app: :mpgs,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
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
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package() do
    [
      maintainers: ["Abdullah Esmail"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp description() do
    "An elixir package for dealing with the MasterCard Payment Gateway Service (MPGS)"
  end
end
