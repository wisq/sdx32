defmodule Sdx32.Action.Mute do
  use GenServer
  require Logger

  alias Sdx32.Mixer
  alias X32Remote.Commands.Mixing

  @settings ["mute", "unmute", "toggle"]
  @port 10023

  def start_link(opts) do
    IO.inspect(opts)
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def cast_event(name, event, payload) do
    GenServer.cast(name, {:event, event, payload})
  end

  def init(payload) do
    IO.inspect(payload)
    Logger.debug("started")
    {:ok, nil}
  end

  def handle_cast(
        {:event, "keyDown",
         %{
           "settings" => %{
             "mixer_ip" => ip,
             "channel" => channel,
             "set" => setting
           }
         }},
        state
      )
      when setting in @settings do
    Mixer.find(ip, @port)
    |> set_mute(setting, channel)

    {:noreply, state}
  end

  def handle_cast({:event, event, _payload}, state) do
    Logger.debug("[#{self() |> inspect()}] Unhandled #{inspect(event)} event")

    {:noreply, state}
  end

  defp set_mute(pid, "mute", channel), do: Mixing.mute(pid, channel)
  defp set_mute(pid, "unmute", channel), do: Mixing.unmute(pid, channel)

  defp set_mute(pid, "toggle", channel) do
    case Mixing.muted?(pid, channel) do
      true -> Mixing.unmute(pid, channel)
      false -> Mixing.mute(pid, channel)
    end
  end
end
