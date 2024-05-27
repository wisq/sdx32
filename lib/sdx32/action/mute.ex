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
      state =
        %State{context: context, set_to: set_to}
        |> subscribe_to_mixer(ip, channel)

      Logger.debug("starting with #{inspect(state)}")
      {:consumer, state}
    else
      _ ->
        {:consumer, %State{context: context}}
    end
  end

  @impl true
  def handle_cast({:action, event, payload}, state) do
    case handle_action(event, payload, state) do
      %State{} = new_state -> {:noreply, [], new_state}
      _ -> {:noreply, [], state}
    end
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

  defp handle_action("keyDown", _, %State{set_to: :mute} = state) do
    Mixing.mute(state.mixer, state.channel)
  end

  defp handle_action("keyDown", _, %State{set_to: :unmute} = state) do
    Mixing.unmute(state.mixer, state.channel)
  end

  defp handle_action("keyDown", _, %State{set_to: :toggle} = state) do
    case state.mute_state do
      :muted -> Mixing.unmute(state.mixer, state.channel)
      :unmuted -> Mixing.mute(state.mixer, state.channel)
      nil -> Logger.error("No current mute state, cannot toggle")
    end
  end

  defp handle_action("keyUp", _, %State{} = state) do
    set_button_state(state.mute_state, state.context)
  end

  defp handle_action("didReceiveSettings", %{"settings" => settings}, state) do
    old_ip = state.ip
    old_channel = state.channel

    case parse_settings(settings) do
      {:ok, ^old_ip, ^old_channel, set_to} ->
        %State{state | set_to: set_to}

      {:ok, new_ip, new_channel, set_to} ->
        %State{state | set_to: set_to}
        |> subscribe_to_mixer(new_ip, new_channel)

      :error ->
        state
    end
  end

  defp handle_action(action, payload, _state) do
    IO.inspect(payload, label: action)
  end

  defp set_button_state(button_state, context) do
    Event.send("setState", context, %{state: Map.fetch!(@button_states, button_state)})
  end

  defp subscribe_to_mixer(state, ip, channel) do
    if state.subscription, do: GenStage.stop(state.subscription)

    {:ok, %{session_name: mixer, watcher_name: watcher}} = Mixer.ensure_started(ip)

    {:ok, sub} =
      Subscription.start_link(
        watcher: watcher,
        tag: :mute,
        command: &Mixing.muted?(&1, channel)
      )
      |> IO.inspect()

    GenStage.async_subscribe(self(), to: sub, cancel: :transient)

    # Reset states here and wait for the subscription refresh.
    # If we don't get a refresh, it's because there's no mixer at that IP.
    %State{
      state
      | ip: ip,
        channel: channel,
        mixer: mixer,
        subscription: sub,
        mute_state: nil
    }
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
end
