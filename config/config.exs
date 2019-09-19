import Mix.Config

source_dir = "/Users/Orange/Desktop/svr_proj/trunk"

watch_files =
  [
    # {dir, {file_type, file_regex}}
    {Path.join(source_dir, "libsrc/protocol"), {:protocol, ~r/.*\.proto$/}},
    {Path.join(source_dir, "libsrc/log"), {:oss_desc, ~r/^oss_desc\.xml$/}}
  ]
  |> Enum.into(%{})

remote_addr = "http://127.0.0.1:8759"

config :file_watcher,
  source_dir: source_dir,
  watch_files: watch_files,
  remote_addr: remote_addr
