defmodule Sdx32.Socket do
  use WebSockex
  require Logger

  alias Sdx32.Parameters
  alias Sdx32.Event

  @prefix "[#{inspect(__MODULE__)}] "
  @max_reconnects 3

  def start_link(opts) do
    {%Parameters{} = params, opts} = Keyword.pop!(opts, :params)
    opts = Keyword.put_new(opts, :name, __MODULE__)

    url = "ws://localhost:#{params.port}"
    WebSockex.start_link(url, __MODULE__, params, opts)
  end

  def send(%{} = data) do
    json = Jason.encode!(data)
    WebSockex.send_frame(__MODULE__, {:text, json})
  end

  @impl true
  def handle_connect(conn, %Parameters{} = params) do
    Logger.info(@prefix <> "Connected to #{log_peer(conn)}")
    send(self(), :register)
    {:ok, params}
  end

  @impl true
  def handle_disconnect(%{reason: {:remote, 1000, _}}, params) do
    Logger.info(@prefix <> "Stream Deck software is shutting down, exiting normally.")
    System.stop(0)
    {:ok, params}
  end

  @impl true
  def handle_disconnect(%{conn: conn, reason: reason, attempt_number: attempt}, params) do
    Logger.error(@prefix <> "Lost connection to #{log_peer(conn)}: #{inspect(reason)}")

    if attempt > @max_reconnects do
      Logger.error(@prefix <> "Failed to reconnect after #{attempt - 1} attempts, shutting down.")
      System.stop(1)
      {:ok, params}
    else
      Logger.info(@prefix <> "Attempting to reconnect (#{attempt}) ...")
      {:reconnect, params}
    end
  end

  @impl true
  def handle_frame({:text, json}, params) do
    json
    |> Jason.decode!()
    |> Event.handle_event()

    {:ok, params}
  end

  @impl true
  def handle_info(:register, params) do
    json = %{event: params.register_event, uuid: params.plugin_uuid} |> Jason.encode!()
    {:reply, {:text, json}, params}
  end

  defp log_peer(%WebSockex.Conn{host: host, port: port, path: path}) do
    "ws://#{host}:#{port}#{path}"
  end
end
