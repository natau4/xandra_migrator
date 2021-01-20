defmodule XandraMigrator.MixProject do
  use Mix.Project

  def project do
    [
      app: :xandra_migrator,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :distillery, :ex_unit],
        check_plt: true
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:xandra, "~> 0.13"},
      {:ecto, "~> 3.5.4"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 0.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:xandra_launcher, github: "natau4/xandra_launcher"}
    ]
  end
end
