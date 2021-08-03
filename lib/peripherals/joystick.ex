defmodule Peripherals.Joystick do
  use GenServer
  require Logger
 def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    {:ok, js} = Joystick.start_link(0, self())
    js_info = Joystick.info(js)
    Logger.debug("joystick: #{inspect(js_info)}")
    Logger.debug("num axes/buttons: #{js_info.axes}/#{js_info.buttons}")
    {:ok, %{joystick: js}}
  end

  @impl GenServer
  def handle_info({:joystick, event}, state) do
    Logger.debug("event: #{inspect(event)}")
    {:noreply, state}
  end
end
