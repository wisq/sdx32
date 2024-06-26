defmodule Sdx32.Action.Volume do
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
      ip: nil,
      channel: nil,
      set_to: nil,
      subscriptions: [],
      mute_state: nil,
      fader_state: nil
    )
  end

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
    with {:ok, ip, channel} <- parse_settings(settings) do
      state =
        %State{context: context}
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
    state = events |> Enum.reduce(state, &handle_one_event/2)
    {:noreply, [], state}
  end

  defp handle_one_event({:mute, mute}, state) do
    %State{state | mute_state: mute}
    |> set_feedback()
  end

  defp handle_one_event({:fader, value}, state) do
    %State{state | fader_state: value}
    |> set_feedback()
  end

  defp set_feedback(%State{mute_state: mute, fader_state: fader} = state)
       when not is_nil(mute) and not is_nil(fader) do
    percent = round(fader * 100)

    title =
      case mute do
        true -> "MUTED"
        false -> "#{percent}%"
      end

    Event.send("setFeedback", state.context, %{value: title, indicator: %{value: percent}})
    state
  end

  defp set_feedback(%State{} = state) do
    Event.send("setFeedback", state.context, %{value: "not found", indicator: %{value: 0}})
    state
  end

  defp handle_action("dialRotate", %{"ticks" => ticks}, state) do
    case state.fader_state do
      nil ->
        Logger.error("No current fader state, cannot dialRotate")

      old ->
        (old + ticks * 0.01)
        |> min(1.0)
        |> max(0.0)
        |> then(&Mixing.set_fader(state.mixer, state.channel, &1))
    end
  end

  defp handle_action("dialDown", _, state), do: toggle_mute(state)
  defp handle_action("touchTap", %{"hold" => false}, state), do: toggle_mute(state)

  defp handle_action("touchTap", %{"hold" => true}, state) do
    Mixing.set_fader(state.mixer, state.channel, 0.0)
  end

  defp handle_action("didReceiveSettings", %{"settings" => settings}, state) do
    old_ip = state.ip
    old_channel = state.channel

    case parse_settings(settings) do
      {:ok, ^old_ip, ^old_channel} ->
        state

      {:ok, new_ip, new_channel} ->
        state
        |> subscribe_to_mixer(new_ip, new_channel)
        |> set_feedback()

      :error ->
        state
    end
  end

  defp handle_action(action, payload, _state) do
    IO.inspect(payload, label: action)
  end

  defp toggle_mute(state) do
    case state.mute_state do
      nil -> Logger.error("No current mute state, cannot toggle")
      true -> Mixing.unmute(state.mixer, state.channel)
      false -> Mixing.mute(state.mixer, state.channel)
    end
  end

  defp subscribe_to_mixer(state, ip, channel) do
    state.subscriptions |> Enum.each(&GenStage.stop(&1))

    {:ok, %{session_name: mixer, watcher_name: watcher}} = Mixer.ensure_started(ip)

    subs =
      [
        mute: &Mixing.muted?(&1, channel),
        fader: &Mixing.get_fader(&1, channel)
      ]
      |> Enum.map(fn {tag, fun} ->
        {:ok, sub} = Subscription.start_link(watcher: watcher, tag: tag, command: fun)
        GenStage.async_subscribe(self(), to: sub, cancel: :transient)
        sub
      end)

    # Reset states here and wait for the subscription refresh.
    # If we don't get a refresh, it's because there's no mixer at that IP.
    %State{
      state
      | ip: ip,
        channel: channel,
        mixer: mixer,
        subscriptions: subs,
        mute_state: nil,
        fader_state: nil
    }
  end

  defp parse_settings(%{"mixer_ip" => ip, "channel" => channel} = settings) do
    with {:ok, ip_tuple} <- ip |> String.to_charlist() |> :inet.parse_strict_address(),
         true <- X32Remote.Types.Channel.channel?(channel) do
      {:ok, ip_tuple, channel}
    else
      rval ->
        Logger.warning("Invalid settings: #{inspect(settings)}, got #{inspect(rval)}")
        :error
    end
  end
end
