defmodule FileWatcher.Uploader do
  @moduledoc false

  use GenServer
  require Logger

  defstruct upload_files: MapSet.new(), timer: nil

  # wait @upload_delay milliseconds after add(file), to merge several changes on same file
  @upload_delay 10_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Add a file to upload to remote server.

  The uploader will always wait @upload_delay milliseconds to ensure all changes
  intended to perform on this file is done. A new call will refresh the timer.
  """
  def add(file) do
    GenServer.cast(__MODULE__, {:add, file})
  end

  @impl true
  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:add, file}, %{upload_files: upload_files, timer: timer}) do
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

    {:noreply, state}
  end

  @impl true
  def handle_info(:upload, %{upload_files: upload_files}) do
    upload_files
    |> Enum.group_by(
      fn {file_type, _} -> file_type end,
      fn {_, file_path} -> file_path end
    )
    |> Enum.each(fn {file_type, file_paths} -> upload(file_type, file_paths) end)

    {:noreply, %__MODULE__{}}
  end

  defp upload(file_type, file_paths) do
    Logger.info("Uploading #{inspect(file_type)} files: #{inspect(file_paths)}")

    upload_url =
      Application.fetch_env!(:file_watcher, :upload_urls)
      |> Keyword.get(file_type)

    post_body = {
      :multipart,
      Enum.flat_map(Enum.with_index(file_paths), fn {file_path, i} ->
        [
          # file path
          {"filepath#{i}", file_path},
          # file content
          {:file, file_path,
           {"form-data", [name: ~s("file#{i}"), filename: ~s("#{Path.basename(file_path)}")]}, []}
        ]
      end)
    }

    case FileWatcher.HttpProxy.post(upload_url, post_body) do
      {:ok, %HTTPoison.Response{status_code: 200} = response} ->
        response
        |> HTTPoison.Handlers.Multipart.decode_body()
        |> update_file()

      {:ok, response} ->
        Logger.error("Server response error: #{inspect(response)}")

      {:error, reason} ->
        Logger.error("HTTP post error: #{inspect(reason)}")
    end
  end

  #  Retrieve changed files from server, and update local ones.
  #  A response_list is a (decoded) multipart form-data list, contain several files each is represented as
  #  a {file_path, file_content} multipart pair.
  defp update_file([{_path_meta, file_path}, {_file_meta, file_content} | response_list]) do
    # map file path from remote dir to local dir
    file_path =
      String.replace_prefix(
        file_path,
        Application.fetch_env!(:file_watcher, :remote_dir),
        Application.fetch_env!(:file_watcher, :source_dir)
      )

    case File.write(file_path, file_content) do
      :ok ->
        Logger.info("Update file <#{file_path}> success")
        update_file(response_list)

      {:error, reason} ->
        Logger.error("Update file <#{file_path}> failed: #{reason}")
    end
  end

  # Tail recursion of response_list, do nothing.
  defp update_file([]), do: nil

  # Invalid responses, just ignore.
  defp update_file(_other), do: :ignore
end
