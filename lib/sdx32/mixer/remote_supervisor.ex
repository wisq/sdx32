defmodule Sdx32.Mixer.RemoteSupervisor do
  use DynamicSupervisor

  @name __MODULE__

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @name)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def ensure_started(ip, port) when is_tuple(ip) do
    prefix = name_prefix(ip, port)

    opts = [
      ip: ip,
      port: port,
      name: super_name(prefix),
      client_name: client_name(prefix),
      session_name: session_name(prefix),
      watcher_name: watcher_name(prefix)
    ]

    with {:ok, pid} <- DynamicSupervisor.start_child(@name, {X32Remote.Supervisor, opts}) do
      {:ok, Map.new(opts) |> Map.put(:pid, pid)}
    else
      {:error, {:already_started, pid}} ->
        {:ok, Map.new(opts) |> Map.put(:pid, pid)}
    end
  end

  def terminate_child(ip, port) do
    case whereis(ip, port) do
      nil -> {:error, :not_found}
      pid when is_pid(pid) -> DynamicSupervisor.terminate_child(@name, pid)
    end
  end

  defp whereis(ip, port), do: name_prefix(ip, port) |> super_name() |> Process.whereis()

  defp super_name(prefix), do: Module.concat(prefix, Supervisor)
  defp client_name(prefix), do: Module.concat(prefix, Client)
  defp session_name(prefix), do: Module.concat(prefix, Session)
  defp watcher_name(prefix), do: Module.concat(prefix, Watcher)

  defp name_prefix(ip, port) when is_tuple(ip) do
    ip_str =
      ip
      |> Tuple.to_list()
      |> Enum.join("_")

    Module.concat(
      Sdx32.Mixer,
      :"At_#{ip_str}_#{port}"
    )
  end
end
