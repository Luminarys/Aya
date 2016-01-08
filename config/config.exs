use Mix.Config

config :logger,
  level: :info

config :aya,
  port: 4000,
  purge_idle_torrents: true,
  announce: 1800,
  min_announce: 1800,
  max_returned_peers: 50,
  use_whitelist: false,
  whitelist: [],
  reap_interval: 60,
  reap_multiplier: 1.5,
  driver_pool_size: 10,
  require_passkey: false,
  driver: Aya.Driver.Default
