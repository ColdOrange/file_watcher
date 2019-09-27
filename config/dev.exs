import Config

# path mapping between local and remote project dir
source_dir = "/Users/Orange/Desktop/svr_proj/trunk"
remote_dir = "/Users/Orange/Desktop/svr_proj/trunk"

watch_files =
  [
    # {dir, {file_type, file_regex}}
    {Path.join(source_dir, "libsrc/protocol"), {:protocol, ~r/.*\.proto$/}},
    {Path.join(source_dir, "libsrc/log"), {:oss_desc, ~r/^oss_desc\.xml$/}}
  ]
  |> Enum.into(%{})

remote_addr = "http://127.0.0.1:8759"

upload_urls = [
  # file_type: upload_url
  protocol: URI.merge(remote_addr, "/upload/protocol") |> to_string(),
  oss_desc: URI.merge(remote_addr, "/upload/oss_desc") |> to_string()
]

http_proxy = nil

config :file_watcher,
  source_dir: source_dir,
  remote_dir: remote_dir,
  watch_files: watch_files,
  upload_urls: upload_urls,
  http_proxy: http_proxy
