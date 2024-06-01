defmodule Sdx32.Parameters do
  @enforce_keys [:port, :plugin_uuid, :register_event, :info]
  defstruct(@enforce_keys)

  alias Sdx32.Parameters.ArgsFromEnv

  def from_args(args) do
    args
    |> parse_args()
    |> then(&struct!(__MODULE__, &1))
  end

  def to_json(%__MODULE__{} = params) do
    params
    |> Map.from_struct()
    |> Jason.encode!()
  end

  def from_json(json) do
    json
    |> Jason.decode!()
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> then(&struct!(__MODULE__, &1))
  end

  defp parse_args(["-port", port | rest]) do
    parse_args(rest)
    |> Map.put(:port, String.to_integer(port))
  end

  defp parse_args(["-pluginUUID", uuid | rest]) do
    parse_args(rest)
    |> Map.put(:plugin_uuid, uuid)
  end

  defp parse_args(["-registerEvent", event | rest]) do
    parse_args(rest)
    |> Map.put(:register_event, event)
  end

  defp parse_args(["-info", json | rest]) do
    parse_args(rest)
    |> Map.put(:info, Jason.decode!(json))
  end

  defp parse_args(["-argsFromEnv", env_var]) do
    System.get_env(env_var)
    |> ArgsFromEnv.parse()
    |> parse_args()
  end

  defp parse_args([]), do: %{}
end
