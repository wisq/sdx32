defmodule Sdx32.Action.Mute do
  use GenServer
  require Logger

  alias Sdx32.Event
  alias Sdx32.Mixer
  alias X32Remote.Commands.Mixing

  @poll 1_000

  defmodule State do
    @enforce_keys [:context, :ip, :channel]
    defstruct(@enforce_keys)
  end

  @port 10023
  @button_states %{muted: 1, unmuted: 0}

  def start_link(opts) do
    {context, opts} = Keyword.pop!(opts, :context)
    {payload, opts} = Keyword.pop!(opts, :payload)
    GenServer.start_link(__MODULE__, {context, payload}, opts)
  end

  def cast_event(name, event, payload) do
    GenServer.cast(name, {:event, event, payload})
  end

  @impl true
  def init({context, %{"settings" => %{"mixer_ip" => ip, "channel" => channel}}}) do
    Logger.debug("started")
    {:ok, %State{context: context, ip: ip, channel: channel}, @poll}
  end

  @impl true
  def handle_cast(
        {:event, event,
         %{
           "settings" => %{
             "mixer_ip" => ip,
             "channel" => channel,
             "set" => setting
           }
         }},
        state
      ) do
    mixer = Mixer.find(ip, @port)
    state = %State{state | ip: ip, channel: channel}

    case handle_event(event, mixer, setting, state) do
      {:reply, button_state, state} ->
        set_button_state(button_state, state.context)
        {:noreply, state, @poll}

      {:noreply, state} ->
        {:noreply, state, 0}
    end
  end

  @impl true
  def handle_cast({:event, event, _payload}, state) do
    Logger.debug("[#{self() |> inspect()}] Non-matching #{inspect(event)} frame")
    {:noreply, state, @poll}
  end

  @impl true
  def handle_info(:timeout, state) do
    case Mixer.find(state.ip, @port) |> Mixing.muted?(state.channel) do
      true -> :muted
      false -> :unmuted
    end
    |> set_button_state(state.context)

    {:noreply, state, @poll}
  end

  defp handle_event("keyDown", mixer, "mute", state) do
    Mixing.mute(mixer, state.channel)
    {:reply, :muted, state}
  end

  defp handle_event("keyDown", mixer, "unmute", state) do
    Mixing.unmute(mixer, state.channel)
    {:reply, :unmuted, state}
  end

  defp handle_event("keyDown", mixer, "toggle", state) do
    case Mixing.muted?(mixer, state.channel) do
      true -> handle_event("keyDown", mixer, "unmute", state)
      false -> handle_event("keyDown", mixer, "mute", state)
    end
  end

  defp handle_event("keyUp", _, _, state) do
    {:noreply, state}
  end

  defp handle_event(event, _, _, state) do
    Logger.debug("[#{self() |> inspect()}] Unhandled #{inspect(event)} frame")
    {:noreply, state}
  end

  defp set_button_state(button_state, context) do
    Event.send("setState", context, %{state: Map.fetch!(@button_states, button_state)})
  end
end
