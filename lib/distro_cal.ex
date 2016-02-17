defmodule Distro.DistroCal do
  use GenServer
  require Logger

  def start_link, do: GenServer.start_link(__MODULE__, [], name: {:global, __MODULE__})

  def add(x, y), do: GenServer.call({:global, __MODULE__}, {:cal, x, y})

  def handle_call({:cal, x, y}, _from, state) do
    { :reply, x + y, state }
  end
end
