import Config

config :sdx32, params_from: :argv
config :x32_remote, start: false

import_config("#{Mix.env()}.exs")
