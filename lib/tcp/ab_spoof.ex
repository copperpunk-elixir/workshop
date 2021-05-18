defmodule AbSpoof do
  use GenServer
  require Logger
  
  def start_link(config) do
    {:ok, pid} = GenServer.start_link(__MODULE__, config, name: __MODULE__)
    GenServer.cast(__MODULE__, {:begin, config})
    {:ok, pid}
  end

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.warn("terminated AbSpoof with port: #{state.port} for reason #{inspect(reason)}")
    :gen_tcp.close(state.socket)
    state
  end

  @impl GenServer
  def handle_cast({:begin, config}, _state) do
    port = Keyword.fetch!(config, :port)
    Logger.debug("port: #{port}")
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :raw, active: true, reuseaddr: true])
    state = %{
      port: port,
      socket: socket
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:tcp, socket, data}, state) do
    Logger.debug("rx on socket #{socket}: #{inspect(data)}")
    {:noreply, state}
  end


end