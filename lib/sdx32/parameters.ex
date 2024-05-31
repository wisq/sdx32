defmodule Sdx32.Parameters do
  @enforce_keys [:port, :plugin_uuid, :register_event, :info]
  defstruct(@enforce_keys)

  def from_environ(env \\ System.get_env()) do
    %{
      port: fetch_env(env, "PORT", &String.to_integer/1),
      plugin_uuid: fetch_env(env, "PLUGIN_UUID"),
      register_event: fetch_env(env, "REGISTER_EVENT"),
      info: fetch_env(env, "INFO", &Jason.decode!/1)
    }
    |> Map.reject(fn {_key, value} -> is_nil(value) end)
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

  defp fetch_env(env, name, parser \\ &Function.identity/1) do
    key = "SDX32_#{name}"

    with {:ok, value} <- Map.fetch(env, key) do
      try do
        parser.(value)
      rescue
        err -> raise "Error parsing #{key}:\n\n#{Exception.message(err)}"
      end
    else
      :error -> nil
    end
  end
end
