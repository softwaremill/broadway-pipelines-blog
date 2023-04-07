defmodule BroadwayPubSubSimple do
  use Broadway

  alias Broadway.Message

  @default_partition 0

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayCloudPubSub.Producer,
           subscription: "projects/softberries/subscriptions/nyc-taxi-sub"},
           concurrency: 1
      ],
      processors: [
        # valid options are: [:concurrency, :min_demand, :max_demand, :partition_by, :spawn_opt, :hibernate_after]
        default: [concurrency: 6, partition_by: &partition/1]
      ],
      batchers: [
        # valid options are: [:concurrency, :batch_size, :max_demand, :batch_timeout, :partition_by, :spawn_opt, :hibernate_after]
        pickup: [
          concurrency: 1,
          batch_size: 5,
          batch_timeout: 2_000
        ],
        dropoff: [
          concurrency: 1,
          batch_size: 5,
          batch_timeout: 2_000
        ],
        enroute: [
          concurrency: 4,
          batch_size: 25,
          batch_timeout: 2_000
        ]
      ]
    )
  end

  defp partition(msg) do
    case Jason.decode(msg.data) do
      {:ok, data} ->
        :erlang.phash2(data["ride_id"])
      _ ->
        :default_partition
    end
  end

  def prepare_messages(messages, _context) do
    IO.puts("Messages in prepare stage: #{inspect(messages)}")
    messages = Enum.map(messages, fn message ->
      Broadway.Message.update_data(message, fn data ->
        %{event: Jason.decode(data)}
      end)
    end)
    messages
  end

  def handle_message(_, %Message{data: %{event: {:ok, taxidata}}} = message, _) do
    IO.puts("#{inspect(self())} Handling first step: #{inspect(taxidata)}")
    message = Broadway.Message.update_data(message, fn _data -> taxidata end)
    case taxidata["ride_status"] do
      "enroute" ->
        message
        |> Broadway.Message.put_batcher(:enroute)
      "pickup" ->
        message
        |> Broadway.Message.put_batcher(:pickup)
      "dropoff" ->
        message
        |> Broadway.Message.put_batcher(:dropoff)
      _ ->
        message
        |> Broadway.Message.failed("invalid-data")
    end
  end

  def handle_message(_, %Message{data: %{event: {:error, err}}} = message, _) do
    IO.puts("#{inspect(self())} Handling parsing error: #{inspect(err)}")
    Broadway.Message.failed(message,"invalid-data")
  end

  def handle_failed(messages, _context) do
    IO.puts("Messages in failed stage: #{inspect(messages)}")
    Enum.map(messages, fn %{status: {:failed, "invalid-data"}} = message ->
      IO.puts("ACK invalid message and log error: #{inspect(message.data)}")
      Broadway.Message.configure_ack(message, on_failure: :ack)
      message -> message
    end)
  end

  def handle_batch(:enroute, messages, batch_info, _) do
    IO.puts("#{inspect(self())} Enroute Batch #{batch_info.batch_key}")
    list = messages |> Enum.map(fn e -> e.data end)
    IO.inspect(list, label: "Got enroute batch: ")
    messages
  end

  def handle_batch(:pickup, messages, batch_info, _) do
    IO.puts("#{inspect(self())} Pickup Batch #{batch_info.batch_key}")
    list = messages |> Enum.map(fn e -> e.data end)
    IO.inspect(list, label: "Got pickup batch: ")
    messages
  end

  def handle_batch(:dropoff, messages, batch_info, _) do
    IO.puts("#{inspect(self())} Dropoff Batch #{batch_info.batch_key}")
    list = messages |> Enum.map(fn e -> e.data end)
    IO.inspect(list, label: "Got dropoff batch: ")
    messages
  end

  def handle_batch(_batcher, messages, batch_info, _) do
    IO.puts("#{inspect(self())} Batch default #{batch_info.batch_key}")
    IO.puts("handling default batch")
    messages
  end

end
