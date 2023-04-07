defmodule Counter do
  use GenStage

  def start_link(number) do
    GenStage.start_link(Counter, number)
  end

  @spec init(any) :: {:producer, any}
  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, counter) when demand > 0 do
    IO.puts("Demand: #{demand}}")
    events = Enum.to_list(counter..counter+demand-1)
    {:noreply, events, counter + demand}
  end
end
