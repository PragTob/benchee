defmodule Benchee.Mixfile do
  use Mix.Project

  @source_url "https://github.com/bencheeorg/benchee"
  @version "1.0.1"

  def project do
    [
      app: :benchee,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: true,
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.travis": :test,
        "safe_coveralls.travis": :test
      ],
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs],
        plt_file: {:no_warn, "priv/plts/benchee.plt"}
      ],
      name: "Benchee",
      description: """
      Versatile (micro) benchmarking that is extensible. Get statistics such as:
      average, iterations per second, standard deviation and the median.
      """
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "mix"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    []
  end

  defp deps do
    [
      {:deep_merge, "~> 1.0"},
      {:statistex, "~> 1.0"},
      {:ex_guard, "~> 1.3", only: :dev},
      {:credo, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.13", only: :test},
      {:inch_ex, "~> 2.0", only: :docs, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.4", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Tobias Pfeiffer", "Devon Estes"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/benchee/changelog.html",
        "GitHub" => @source_url,
        "Blog posts" => "https://pragtob.wordpress.com/tag/benchee/"
      }
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
