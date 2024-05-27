defmodule Sdx32.Action.Mute do
  use GenStage
  require Logger

  alias Sdx32.Event
  alias Sdx32.Mixer
  alias X32Remote.Commands.Mixing
  alias X32Remote.Subscription

  defmodule State do
    @enforce_keys [:context]
    defstruct(
      context: nil,
      mixer: nil,
      subscription: nil,
      ip: nil,
      channel: nil,
      set_to: nil,
      mute_state: nil
    )
  end

  @button_states %{muted: 1, unmuted: 0}
  @set_to %{
    "mute" => :mute,
    "unmute" => :unmute,
    "toggle" => :toggle
  }

  def start_link(opts) do
    {context, opts} = Keyword.pop!(opts, :context)
    {payload, opts} = Keyword.pop!(opts, :payload)
    GenStage.start_link(__MODULE__, {context, payload}, opts)
  end

  def cast_event(name, event, payload) do
    GenStage.cast(name, {:action, event, payload})
  end

  @impl true
  def init({context, %{"settings" => settings}}) do
    with {:ok, ip, channel, set_to} <- parse_settings(settings) do
      {:ok, %{session_name: mixer, watcher_name: watcher}} = Mixer.ensure_started(ip)

      {:ok, sub} =
        Subscription.start_link(
          watcher: watcher,
          tag: :mute,
          command: &Mixing.muted?(&1, channel)
        )

      state = %State{
        context: context,
        mixer: mixer,
        subscription: sub,
        ip: ip,
        channel: channel,
        set_to: set_to
      }

      Logger.debug("starting with #{inspect(state)}")
      {:consumer, state, subscribe_to: [sub]}
    else
      _ ->
        {:consumer, %State{context: context}}
    end
  end

  @impl true
  def handle_cast({:action, event, %{"settings" => settings}} = cast, state) do
    state = update_settings(settings, state, cast)

    handle_action(event, state)
    {:noreply, [], state}
  end

  @impl true
  def handle_cast({:action, event, _}, state) do
    Logger.debug("[#{self() |> inspect()}] Non-matching #{inspect(event)} frame")
    {:noreply, [], state}
  end

  @impl true
  def handle_events(events, _from, state) do
    case events |> List.last() do
      {:mute, true} -> :muted
      {:mute, false} -> :unmuted
    end
    |> then(fn new_mute_state ->
      set_button_state(new_mute_state, state.context)
      {:noreply, [], %State{state | mute_state: new_mute_state}}
    end)
  end

  defp handle_action("keyDown", %State{set_to: :mute} = state) do
    Mixing.mute(state.mixer, state.channel)
  end

  defp handle_action("keyDown", %State{set_to: :unmute} = state) do
    Mixing.unmute(state.mixer, state.channel)
  end

  defp handle_action("keyDown", %State{set_to: :toggle} = state) do
    case state.mute_state do
      :muted -> Mixing.unmute(state.mixer, state.channel)
      :unmuted -> Mixing.mute(state.mixer, state.channel)
      nil -> Logger.error("No current mute state, cannot toggle")
    end
  end

  defp handle_action("keyUp", %State{} = state) do
    set_button_state(state.mute_state, state.context)
    {:noreply, [], state}
  end

  defp handle_action(event, state) do
    Logger.debug("[#{self() |> inspect()}] Unhandled #{inspect(event)} frame")
    {:noreply, state}
  end

  defp set_button_state(button_state, context) do
    Event.send("setState", context, %{state: Map.fetch!(@button_states, button_state)})
  end

  defp parse_settings(%{"mixer_ip" => ip, "channel" => channel, "set" => set} = settings) do
    with {:ok, ip_tuple} <- ip |> String.to_charlist() |> :inet.parse_strict_address(),
         true <- X32Remote.Types.Channel.channel?(channel),
         {:ok, set_to} <- Map.fetch(@set_to, set) do
      {:ok, ip_tuple, channel, set_to}
    else
      rval ->
        Logger.warning("Invalid settings: #{inspect(settings)}, got #{inspect(rval)}")
        :error
    end
  end

  defp parse_settings(settings) do
    Logger.warning("Invalid settings: #{inspect(settings)}")
    :error
  end

  defp update_settings(_settings, state, _cast) do
    state
  end
end
