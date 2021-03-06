defmodule LoggerHumioBackend.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logger_humio_backend,
      version: "0.0.4",
      elixir: "~> 1.0",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.3.0"},
      {:jason, "~> 1.1"},
      {:credo, "~> 1.5.0-rc.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end

  defp description do
    """
    A Logger backend to support the Humio (humio.com) TCP input log mechanism
    """
  end

  defp package do
    [
      files: ["config", "lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Andreas Kasprzok"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/akasprzok/logger_humio_backend"}
    ]
  end
end
