defmodule Sdx32.Parameters do
  defstruct(
    port: nil,
    plugin_uuid: nil,
    register_event: nil,
    info: nil
  )

  def parse_args(["-port", port_str | rest]) do
    with {:ok, opts} <- parse_args(rest),
         {port, ""} <- Integer.parse(port_str) do
      {:ok, %__MODULE__{opts | port: port}}
    end
  end

  def parse_args(["-pluginUUID", uuid | rest]) do
    with {:ok, opts} <- parse_args(rest) do
      {:ok, %__MODULE__{opts | plugin_uuid: uuid}}
    end
  end

  def parse_args(["-registerEvent", event | rest]) do
    with {:ok, opts} <- parse_args(rest) do
      {:ok, %__MODULE__{opts | register_event: event}}
    end
  end

  def parse_args(["-info", json | rest]) do
    with {:ok, opts} <- parse_args(rest),
         {:ok, info} <- Jason.decode(json) do
      {:ok, %__MODULE__{opts | info: info}}
    end
  end

  def parse_args([]), do: {:ok, %__MODULE__{}}

  def to_json(%__MODULE__{} = opts) do
    opts
    |> Map.from_struct()
    |> Jason.encode!()
  end
end
