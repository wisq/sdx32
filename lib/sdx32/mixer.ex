defmodule Sdx32.Mixer do
  alias Sdx32.Mixer.{Manager, RemoteSupervisor}

  def find(ip, port) do
    Manager.register(self(), ip, port)

    case RemoteSupervisor.whereis(ip, port) do
      pid when is_pid(pid) ->
        pid

      nil ->
        Manager.wait()
        RemoteSupervisor.whereis(ip, port)
    end
  end
end
