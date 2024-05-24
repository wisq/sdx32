defmodule Sdx32.ActionSupervisor do
  use DynamicSupervisor

  @name __MODULE__

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @name)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(module, opts) do
    DynamicSupervisor.start_child(@name, {module, opts})
  end

  def terminate_child(pid) when is_pid(pid) do
    DynamicSupervisor.terminate_child(@name, pid)
  end

  def terminate_child(name) when is_atom(name) do
    case Process.whereis(name) do
      nil -> {:error, :not_found}
      pid when is_pid(pid) -> terminate_child(pid)
    end
  end
end
