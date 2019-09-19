defmodule FileWatcher do
  use Application

  def start(_type, _args) do
    FileWatcher.Supervisor.start_link()
  end
end
