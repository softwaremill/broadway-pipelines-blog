defmodule BroadwayCustomProducer do
  use Broadway

  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Counter, 1},
        transformer: {__MODULE__, :transform, []}
      ],
      processors: [
        default: [concurrency: 1]
      ],
      batchers: [
        default: [concurrency: 1, batch_size: 1],
      ]
    )
  end


  def prepare_messages(messages, _context) do
    IO.puts("Messages in prepare stage: #{inspect(messages)}")
    messages
  end

  def handle_message(_, message, _) do
    IO.puts("#{inspect(self())} Handling message: #{inspect(message)}")
    Process.sleep(3000)
    message
  end

  def handle_failed(messages, _context) do
    IO.puts("Messages in failed stage: #{inspect(messages)}")
    messages
  end

  def handle_batch(_, messages, batch_info, _) do
    IO.puts("#{inspect(self())} Enroute Batch #{inspect(messages)}")
    messages
  end

  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, :ack_data}
    }
  end

  def ack(:ack_id, successful, failed) do
    # Write ack code here
  end

end
