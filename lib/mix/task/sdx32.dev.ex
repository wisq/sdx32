defmodule Mix.Tasks.Sdx32.Dev do
  use Mix.Task

  alias Sdx32.Parameters

  @params_file "dev.json"

  def run(args) do
    args
    |> Parameters.from_args()
    |> Parameters.to_json()
    |> then(&File.write!(@params_file, &1))

    IO.puts("""

    Wrote parameters to #{inspect(@params_file)}.
    Send SIGTERM to delete, or SIGINT (ctrl-C) to exit and keep ...
    """)

    System.trap_signal(:sigterm, fn ->
      File.rm!("dev.json")
      IO.puts("Deleted #{inspect(@params_file)}.")
      :ok
    end)

    Process.sleep(:infinity)
  end
end
