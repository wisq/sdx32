defmodule Sdx32.Socket do
  use WebSockex

  alias Sdx32.Parameters

  def start_link(opts) do
    {%Parameters{} = params, opts} = Keyword.pop!(opts, :params)
    opts = Keyword.put_new(opts, :name, __MODULE__)

    url = "ws://localhost:#{params.port}"
    WebSockex.start_link(url, __MODULE__, params, opts)
  end

  def handle_connect(_conn, %Parameters{} = params) do
    IO.puts("Connected")
    send(self(), :register)
    {:ok, params}
  end

  def handle_frame({:text, json}, params) do
    data = Jason.decode!(json)
    IO.inspect(data)
    {:ok, params}
  end

  def handle_info(:register, params) do
    json = %{event: params.register_event, uuid: params.plugin_uuid} |> Jason.encode!()
    {:reply, {:text, json}, params}
  end
end
