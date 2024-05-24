defmodule Mix.Tasks.Sdx32.Dev do
  use Mix.Task

  alias Sdx32.Parameters

  @params_file "dev.json"

  def run(args) do
    with {:ok, opts} <- Parameters.parse_args(args) do
      File.write!(@params_file, Parameters.to_json(opts))

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
    else
      other -> raise "Unknown return value: #{inspect(other)}"
    end
  end
end
