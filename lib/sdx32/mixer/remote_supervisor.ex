defmodule Sdx32.Mixer.RemoteSupervisor do
  use DynamicSupervisor

  @name __MODULE__

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: @name)
  end

  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(ip, port) do
    with {:ok, ip_tuple} <- ip |> String.to_charlist() |> :inet.parse_strict_address() do
      opts = [
        ip: ip_tuple,
        port: port,
        name: super_name(ip, port),
        client_name: client_name(ip, port),
        session_name: session_name(ip, port)
      ]

      DynamicSupervisor.start_child(@name, {X32Remote.Supervisor, opts})
    end
  end

  def terminate_child(ip, port) do
    case whereis(ip, port, :super) do
      nil -> {:error, :not_found}
      pid when is_pid(pid) -> DynamicSupervisor.terminate_child(@name, pid)
    end
  end

  def whereis(ip, port, type \\ :session)
  def whereis(ip, port, :super), do: super_name(ip, port) |> Process.whereis()
  def whereis(ip, port, :client), do: client_name(ip, port) |> Process.whereis()
  def whereis(ip, port, :session), do: session_name(ip, port) |> Process.whereis()

  defp super_name(ip, port), do: name_prefix(ip, port) |> Module.concat(Supervisor)
  defp client_name(ip, port), do: name_prefix(ip, port) |> Module.concat(Client)
  defp session_name(ip, port), do: name_prefix(ip, port) |> Module.concat(Session)

  defp name_prefix(ip, port) do
    ip_str = ip |> String.replace(~r/[^0-9]+/, "_")

    Module.concat(
      Sdx32.Mixer,
      :"At_#{ip_str}_#{port}"
    )
  end
end
