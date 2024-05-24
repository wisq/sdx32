defmodule Sdx32.Event do
  require Logger

  alias Sdx32.{Action, Socket}

  def send(event, context, payload) do
    Socket.send(%{
      event: event,
      context: context,
      payload: payload
    })
  end

  def handle_event(%{
        "action" => action,
        "context" => context,
        "event" => "willAppear",
        "payload" => payload
      }) do
    Action.create(action, context, payload)
  end

  def handle_event(%{
        "action" => action,
        "context" => context,
        "event" => "willDisappear"
      }) do
    Action.destroy(action, context)
  end

  def handle_event(%{
        "action" => action,
        "context" => context,
        "event" => event,
        "payload" => payload
      }) do
    Action.cast_event(action, context, event, payload)
  end

  def handle_event(%{} = event) do
    Logger.debug("Unhandled event:\n#{inspect(event, pretty: true)}")
  end
end
