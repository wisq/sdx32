defmodule Sdx32.Action.Mute do
  use GenServer
  require Logger

  def start_link(opts) do
    IO.inspect(opts)
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def cast_event(name, event, payload) do
    GenServer.cast(name, {:event, event, payload})
  end

  def init(_) do
    Logger.debug("started")
    {:ok, nil}
  end

  def handle_cast({:event, event, payload}, state) do
    Logger.debug(
      "[#{self() |> inspect()}] Got #{inspect(event)} event:\n#{inspect(payload, pretty: true)}"
    )

    {:noreply, state}
  end
end
