defmodule AbSpoof do
  use GenServer
  require Logger
  @server_port 35151
  @local_ip {127, 0, 0, 1}
  @ab_ip {192, 168, 7, 250}

  def start_server() do
    config = [is_server: true]
    start_link(config)
  end

  def start_client(ip_address \\ @local_ip) do
    config = [is_server: false, ip_address: ip_address]
    start_link(config)
  end

  def start_ab_client() do
    start_client(@ab_ip)
  end

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
    Logger.warn("terminated AbSpoof with reason #{inspect(reason)}")
    :gen_tcp.close(state.socket)
    state
  end

  @impl GenServer
  def handle_cast({:begin, config}, _state) do
    is_server = Keyword.fetch!(config, :is_server)
    Logger.debug("Is Server: #{is_server}")

    socket =
      if is_server do
        {:ok, socket} =
          :gen_tcp.listen(@server_port, [:binary, packet: :raw, active: true, reuseaddr: true])

        :gen_tcp.accept(socket)
        socket
      else
        ip = Keyword.fetch!(config, :ip_address)
        {:ok, socket} = :gen_tcp.connect(ip, @server_port, [:binary, active: true, packet: :raw])
        socket
      end

    state = %{
      socket: socket
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:send, message}, state) do
    Logger.debug("send msg #{message}")
    result = :gen_tcp.send(state.socket, message)
    Logger.debug("result: #{inspect(result)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:trigger_calcs, state) do
    msg = "3\n"
    GenServer.cast(__MODULE__, {:send, msg})
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:tcp, _socket, data}, state) do
    Logger.debug("rx: #{inspect(data)}")
    {:noreply, state}
  end

  @spec send_tcp(binary()) :: atom()
  def send_tcp(message) do
    GenServer.cast(__MODULE__, {:send, message})
  end

  @spec update_winds(integer(), integer()) :: atom
  def update_winds(w \\ 5, delay \\ 250) do
    msg1 = "2,1,0,#{w},#{w},#{w}\n"
    msg2a = "2,2,100,#{2*w},#{2*w},#{2*w}\n"
    msg2b = "2,3,300,#{3*w},#{3*w},#{3*w}\n"
    msg2c = "2,4,1000,#{w},#{w},#{w}\n"
    msgs = [msg1, msg2a, msg2b, msg2c]

    Enum.each(msgs, fn msg ->
      GenServer.cast(__MODULE__, {:send, msg})
      Process.sleep(delay)
    end)
    Process.sleep(delay)
    trigger_calculation()
  end

  @spec trigger_calculation() :: atom()
  def trigger_calculation() do
    GenServer.cast(__MODULE__, :trigger_calcs)
  end

  @spec update_cycle() :: atom()
  def update_cycle() do
    Enum.each(1..20, fn x ->
      update_winds(x)
      y = 2000 + x*100
      Logger.debug("delay #{y}")
      Process.sleep(y)
    end)
  end
end
