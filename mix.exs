defmodule FileWatcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :file_watcher,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {FileWatcher, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:file_system, "~> 0.2"},
      {:httpoison, "~> 1.5"}
    ]
  end
end
