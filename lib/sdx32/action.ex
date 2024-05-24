defmodule Sdx32.Action do
  alias Sdx32.Action
  alias Sdx32.ActionSupervisor

  @actions %{
    "net.wisq.sdx32.mute" => Action.Mute,
    "net.wisq.sdx32.volume" => Action.Volume
  }

  def create(action, context, payload) do
    with {:ok, module, name} <- lookup_action(action, context) do
      ActionSupervisor.start_child(module, name: name, payload: payload)
    end
  end

  def destroy(action, context) do
    with {:ok, _, name} <- lookup_action(action, context) do
      ActionSupervisor.terminate_child(name)
    end
  end

  def cast_event(action, context, event, payload) do
    with {:ok, module, name} <- lookup_action(action, context) do
      module.cast_event(name, event, payload)
    end
  end

  defp lookup_action(action, context) do
    with {:ok, module} <- Map.fetch(@actions, action) do
      {:ok, module, Module.concat(module, "Ctx_#{context}")}
    end
  end
end
