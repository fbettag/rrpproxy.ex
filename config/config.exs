# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

if Mix.env() != :prod,
  do:
    config(:git_hooks,
      verbose: true,
      hooks: [
        pre_commit: [
          tasks: [
            "mix clean",
            "mix compile --warnings-as-errors",
            "mix xref deprecated --abort-if-any",
            "mix xref unreachable --abort-if-any",
            "mix format --check-formatted",
            # "mix credo --strict",
            # "mix doctor --summary",
            "mix test"
          ]
        ]
      ]
    )

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
