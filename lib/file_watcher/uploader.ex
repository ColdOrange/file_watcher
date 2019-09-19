defmodule FileWatcher.Uploader do
  require Logger
  use GenServer

  defstruct upload_files: MapSet.new(), timer: nil

  # wait @upload_delay milliseconds after add(file), to merge several changes on same file
  @upload_delay 10000

  # remote server address and urls
  @remote_addr Application.get_env(:file_watcher, :remote_addr)
  @url_upload_protocol URI.merge(@remote_addr, "/upload/protocol") |> to_string()
  @url_upload_oss_desc URI.merge(@remote_addr, "/upload/oss_desc") |> to_string()

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Add a file to upload to remote server.

  The uploader will always wait @upload_delay milliseconds to ensure all changes
  intended to perform on this file is done. A new call will refresh the timer.
  """
  def add(file) do
    GenServer.call(__MODULE__, {:add, file})
  end

  @impl true
  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call({:add, file}, _from, %{upload_files: upload_files, timer: timer}) do
    if timer != nil do
      case Process.cancel_timer(timer) do
        false ->
          Logger.error("Cancel last timer: #{inspect(timer)} failed")

        time_left ->
          Logger.debug("Cancel last timer: #{inspect(timer)}, time left: #{time_left}")
      end
    end

    timer = Process.send_after(self(), :upload, @upload_delay)
    Logger.debug("Add new timer: #{inspect(timer)}")

    state = %{upload_files: MapSet.put(upload_files, file), timer: timer}
    Logger.info("Add file: #{inspect(file)}, state: #{inspect(state)}")

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:upload, %{upload_files: upload_files}) do
    upload_files
    |> Enum.each(fn {file_type, file_path} = file ->
      Logger.debug("Uploading file: #{inspect(file)}")
      upload(file_type, file_path)
    end)

    {:noreply, %__MODULE__{}}
  end

  defp upload(:protocol, file_path) do
    Logger.info("Upload protocol: <#{file_path}>")

    case HTTPoison.post(@url_upload_protocol, {:file, file_path}) do
      {:ok, response} -> Logger.info("#{inspect(response)}")
      {:error, reason} -> Logger.error("#{inspect(reason)}")
    end
  end

  defp upload(:oss_desc, file_path) do
    Logger.info("Upload oss_desc: <#{file_path}>")

    case HTTPoison.post(@url_upload_oss_desc, {:file, file_path}) do
      {:ok, response} -> Logger.info("#{inspect(response)}")
      {:error, reason} -> Logger.error("#{inspect(reason)}")
    end
  end
end
