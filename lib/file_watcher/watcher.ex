defmodule FileWatcher.Watcher do
  @moduledoc false

  use GenServer
  require Logger

  # files to watch, tuple: {dir, {file_type, file_regex}}
  @watch_files Application.fetch_env!(:file_watcher, :watch_files)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    dirs = @watch_files |> Map.keys()
    {:ok, watcher_pid} = FileSystem.start_link(dirs: dirs)
    FileSystem.subscribe(watcher_pid)
    {:ok, %{watcher_pid: watcher_pid}}
  end

  @impl true
  def handle_info({:file_event, _watcher_pid, {file_path, events}}, state) do
    with {true, file_type} <- is_watch_file(file_path),
         true <- is_watch_events(events) do
      file = {file_type, file_path}
      Logger.info("File event: #{inspect(file)} #{inspect(events)}")
      FileWatcher.Uploader.add(file)
    end

    {:noreply, state}
  end

  defp is_watch_file(path) do
    @watch_files
    |> Enum.find(fn {dir, {_file_type, file_regex}} ->
      Path.relative_to(path, dir) != path and
        String.match?(Path.basename(path), file_regex)
    end)
    |> case do
      {_dir, {file_type, _file_regex}} -> {true, file_type}
      nil -> false
    end
  end

  defp is_watch_events(events) do
    Enum.member?(events, :created) or
      Enum.member?(events, :modified) or
      Enum.member?(events, :renamed)
  end
end
