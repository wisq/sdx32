defmodule Sdx32.MixProject do
  use Mix.Project

  def project do
    [
      app: :sdx32,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Sdx32, []},
      extra_applications: [:logger]
    ]
  end

  defp releases do
    [
      sdx32: [
        steps: [:assemble, &copy_extras/1]
      ]
    ]
  end

  @copy_dirs ["html", "icons"]
  @copy_files ["manifest.json", "sdx32.sh", "sdx32.bat"]

  defp copy_extras(rel) do
    @copy_dirs
    |> Enum.each(fn dir ->
      IO.puts("Copying directory: #{dir}")
      File.cp_r!(dir, Path.join(rel.path, dir))
    end)

    @copy_files
    |> Enum.each(fn file ->
      IO.puts("Copying file: #{file}")
      File.cp!(file, Path.join(rel.path, file))
    end)

    rel
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jason, "~> 1.4"},
      {:websockex, "~> 0.4.3"},
      {:x32_remote, github: "wisq/x32_remote", tag: "89ec84594c27f417b4683a285271f120aa4e3a84"}
    ]
  end
end
