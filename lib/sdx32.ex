defmodule Sdx32 do
  use Application
  require Logger

  alias Sdx32.Parameters

  @params_from Application.compile_env!(:sdx32, :params_from)

  def start(_type, _args) do
    children = children(@params_from)
    Enum.empty?(children) || Logger.info("Sdx32 starting ...")
    Supervisor.start_link(children, strategy: :one_for_one, name: Sdx32.Supervisor)
  end

  def run do
    {:ok, _} = Application.ensure_all_started(:sdx32)
    Process.sleep(:infinity)
  end

  defp children(:none), do: []

  defp children({:file, file}) do
    File.read!(file)
    |> Parameters.from_json()
    |> children_with_params()
  end

  defp children(:argv) do
    System.argv()
    |> Parameters.from_args()
    |> children_with_params()
  end

  defp children_with_params(%Parameters{} = params) do
    [
      Sdx32.ActionSupervisor,
      Sdx32.Mixer.RemoteSupervisor,
      Sdx32.Mixer.Manager,
      {Sdx32.Socket, params: params}
    ]
  end
end
