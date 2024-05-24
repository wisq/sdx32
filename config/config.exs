import Config

config :sdx32, params_from: :argv

import_config("#{Mix.env()}.exs")
