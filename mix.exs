defmodule Mnemoniac.MixProject do
  use Mix.Project

  def project do
    [
      app: :mnemoniac,
      version: "0.1.5",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Mnemonic generation according to the BIP-39 standard",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: [
        maintainers: ["Ayrat Badykov"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/ayrat555/mnemoniac"}
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_pbkdf2, "~> 0.8.5", only: [:test]},
      {:ex_secp256k1, "~> 0.7.6", only: [:test]},
      {:ex_base58, "~> 0.6.5", only: [:test]}
    ]
  end
end
