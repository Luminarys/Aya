defmodule Aya.Mixfile do
  use Mix.Project

  def project do
    [app: :aya,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :cowboy, :plug], mod: {Aya, []}]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:bencodex, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:exrm, "~> 0.18.1"},
      {:eflame2, ~r/.*/, git: "https://github.com/slfritchie/eflame.git", compile: "rebar compile", app: false, env: :dev},
      {:httpoison, "~> 0.8.0", env: :dev},
      {:benchfella, "~> 0.3.0", env: :dev}
    ]
  end
end
