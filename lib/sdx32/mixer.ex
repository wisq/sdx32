defmodule Sdx32.Mixer do
  alias Sdx32.Mixer.{Manager, RemoteSupervisor}

  @default_port 10023

  def ensure_started(ip, port \\ @default_port) when is_tuple(ip) do
    Manager.register(self(), ip, port)
    RemoteSupervisor.ensure_started(ip, port)
  end
end
