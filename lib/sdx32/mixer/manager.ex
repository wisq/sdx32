defmodule Sdx32.Mixer.Manager do
  use GenServer
  require Logger

  alias Sdx32.Mixer.RemoteSupervisor

  defmodule State do
    defstruct(
      mixers: %{},
      clients: %{}
    )
  end

  @name __MODULE__

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: @name)
  end

  def register(pid, ip, port) do
    GenServer.cast(@name, {:register, pid, ip, port})
  end

  def wait, do: GenServer.call(@name, :wait)

  @impl true
  def init(_) do
    {:ok, %State{}}
  end

  @impl true
  def handle_call(:wait, _from, state), do: {:reply, :ok, state}

  @impl true
  def handle_cast({:register, pid, ip, port}, state) do
    {:noreply,
     state
     |> replace_client(pid, {ip, port})
     |> cleanup_unused()}
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply,
     state
     |> delete_client(pid)
     |> cleanup_unused()}
  end

  defp replace_client(%State{} = state, pid, {_, _} = new_ip_port) do
    case Map.fetch(state.clients, pid) do
      :error ->
        Logger.debug("Monitoring new process: #{inspect(new_ip_port)}")
        Process.monitor(pid)

        %State{
          state
          | clients: state.clients |> Map.put(pid, new_ip_port),
            mixers: state.mixers |> add_mixer_client(new_ip_port, pid)
        }

      {:ok, ^new_ip_port} ->
        Logger.debug("No change for process: #{inspect(new_ip_port)}")
        state

      {:ok, {_, _} = old_ip_port} ->
        Logger.debug("Replacing process: #{inspect(old_ip_port)} -> #{inspect(new_ip_port)}")

        %State{
          state
          | clients: state.clients |> Map.replace!(pid, new_ip_port),
            mixers:
              state.mixers
              |> delete_mixer_client(old_ip_port, pid)
              |> add_mixer_client(new_ip_port, pid)
        }
    end
  end

  defp delete_client(%State{} = state, pid) do
    case Map.fetch(state.clients, pid) do
      :error ->
        Logger.debug("Duplicate delete_client")
        state

      {:ok, {_, _} = old_ip_port} ->
        Logger.debug("Deleting client")

        %State{
          state
          | clients: state.clients |> Map.delete(pid),
            mixers: state.mixers |> delete_mixer_client(old_ip_port, pid)
        }
    end
  end

  defp add_mixer_client(mixers, {ip, port} = ip_port, pid) do
    mixers
    |> Map.get_and_update(ip_port, fn
      nil ->
        Logger.debug("Registered new mixer at #{inspect(ip_port)}")
        {nil, MapSet.new([pid])}

      set ->
        Logger.debug("Adding new PID to existing mixer at #{inspect(ip_port)}")
        {set, MapSet.put(set, pid)}
    end)
    |> elem(1)
  end

  defp delete_mixer_client(mixers, {_, _} = ip_port, pid) do
    mixers
    |> Map.update!(ip_port, &MapSet.delete(&1, pid))
  end

  defp cleanup_unused(%State{} = state) do
    mixers =
      state.mixers
      |> Map.reject(fn {{ip, port} = ip_port, set} ->
        if Enum.empty?(set) do
          Logger.debug("Shutting down unused mixer on #{inspect(ip_port)}")
          RemoteSupervisor.terminate_child(ip, port)
          true
        end
      end)

    %State{state | mixers: mixers}
  end
end
