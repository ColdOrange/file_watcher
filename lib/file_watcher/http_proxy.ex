defmodule FileWatcher.HttpProxy do
  use HTTPoison.Base

  @http_proxy Application.fetch_env!(:file_watcher, :http_proxy)

  def process_request_options(options) do
    options
    |> Keyword.put(:proxy, @http_proxy)
    |> Keyword.put(:recv_timeout, 600_000)
  end
end
