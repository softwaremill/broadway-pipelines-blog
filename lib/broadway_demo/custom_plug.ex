defmodule BroadwayDemoWeb.CustomPlug do
  import Plug.Conn
  # import Floki

  def init(default), do: default

  def call(conn, default) do
    conn = register_before_send conn, fn conn ->
      # IO.inspect %{url: conn.request_path, where: opts[:where]}
      # IO.inspect("Body: #{conn.resp_body}")
      {:ok, document} = Floki.parse_document(conn.resp_body)
      hrefs = Floki.find(document, "[href]")
      Enum.each(hrefs, fn e -> IO.puts("Href: #{inspect(e)}") end)
      path = "output/index.html"
      with :ok <- File.mkdir_p(Path.dirname(path)) do
        File.write(path, conn.resp_body)
      end
      conn
    end
    conn
  end

  def opts() do

  end
end
