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

  def cli do
    [preferred_envs: [release: :prod]]
  end

  defp releases do
    [
      sdx32: [
        include_executables_for: [platform_executables()],
        steps: [:assemble, &copy_extras/1],
        path: "release/net.wisq.sdx32.sdPlugin/#{platform()}"
      ]
    ]
  end

  defp platform do
    case :os.type() do
      {:unix, :darwin} -> :macos
      {:win32, :nt} -> :windows
      other -> raise "Unsupported OS: #{inspect(other)}"
    end
  end

  defp platform_executables do
    case platform() do
      :macos -> :unix
      :windows -> :windows
    end
  end

  @copy_dirs ["html", "icons"]
  @copy_files ["manifest.json", "sdx32.sh", "sdx32.bat"]

  defp copy_extras(rel) do
    parent = Path.dirname(rel.path)

    @copy_dirs
    |> Enum.each(fn dir ->
      IO.puts("Copying directory: #{dir}")
      File.cp_r!(dir, Path.join(parent, dir))
    end)

    @copy_files
    |> Enum.each(fn file ->
      IO.puts("Copying file: #{file}")
      File.cp!(file, Path.join(parent, file))
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
