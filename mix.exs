defmodule PeekAppSDK.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :peek_app_sdk,
      name: "Peek SDK",
      source_url: "https://github.com/peek-travel/peek_app_sdk",
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [
        tool: ExCoveralls,
        test_task: "test",
        summary: [threshold: 90]
      ],
      package: package()
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test,
        "coveralls.lcov": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PeekAppSDK.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "assets"]
  defp elixirc_paths(_), do: ["lib", "assets"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:gettext, "~> 1.0"},
      {:joken, "~> 2.3"},
      {:tesla, "~> 1.4"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:finch, "~> 0.13"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},

      # Test dependencies
      {:mimic, "~> 1.7", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:bypass, "~> 2.1", only: :test},

      # Development dependencies
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"],
      "assets.setup": ["esbuild.install --if-missing"],
      "assets.build": ["esbuild odyssey_hooks", "esbuild odyssey_web_components"],
      "assets.deploy": [
        "esbuild odyssey_hooks --minify",
        "esbuild odyssey_web_components --minify",
        "phx.digest"
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/peek-travel/peek_app_sdk"
      },
      files: ~w(mix.exs lib/** assets/** package.json priv/static/odyssey_hooks.min.js priv/static/odyssey_web_components.min.js)
    ]
  end
end
