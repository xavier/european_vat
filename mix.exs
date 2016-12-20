defmodule EuropeanVat.Mixfile do
  use Mix.Project

  def project do
    [app: :european_vat,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     description: description,
     package: package,
     source_url: "https://github.com/xavier/european_vat",
     homepage_url: "https://github.com/xavier/european_vat"]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :httpoison]
    ]
  end

  defp description do
    "European Union VAT number utilities"
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Xavier Defrang"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/xavier/european_vat"}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:httpoison, "~> 0.10.0"},
     {:sweet_xml,  "~> 0.6.0"},
     {:poison, "~> 2.0"},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.11", only: :dev}]
  end
end
