import Config

# path mapping between local and remote project dir
source_dir = "c:/Users/wenjuxu/Desktop/KOServer"
remote_dir = "/data1/home/wenjuxu/KOServer"

watch_files =
  [
    # {dir, {file_type, file_regex}}
    {Path.join(source_dir, "libsrc/protocol"), {:protocol, ~r/.*\.proto$/}},
    {Path.join(source_dir, "libsrc/log"), {:oss_desc, ~r/^oss_desc\.xml$/}},
    {Path.join(source_dir, "excel/excel_config"), {:excel, ~r/^[^~].*\.xlsx$/}}
  ]
  |> Enum.into(%{})

remote_addr = "http://10.125.40.202:8759"

upload_urls = [
  # file_type: upload_url
  protocol: URI.merge(remote_addr, "/upload/protocol") |> to_string(),
  oss_desc: URI.merge(remote_addr, "/upload/oss_desc") |> to_string(),
  excel: URI.merge(remote_addr, "/upload/excel") |> to_string()
]

http_proxy = {:http, "web-proxy.tencent.com", 8080}

config :file_watcher,
  source_dir: source_dir,
  remote_dir: remote_dir,
  watch_files: watch_files,
  upload_urls: upload_urls,
  http_proxy: http_proxy

config :logger, :console, format: "\n$date $time [$level] $levelpad$message\n"
