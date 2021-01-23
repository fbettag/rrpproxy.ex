# RRPproxy

This package implements the [RRPproxy.net](https://rrpproxy.net) API for registering domains with Elixir.

If you need more of their API, just launch a Pull Request.

## Installation

This package can be installed by adding `rrpproxy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rrpproxy, "~> 0.1.7"}
  ]
end
```

## Configuration

Put the following lines into your `config.exs` or better, into your environment
configuration files like `test.exs`, `dev.exs` or `prod.exs.`.

```elixir
config :rrpproxy,
  username: "<your login>",
  password: "<your password>",
  ote: true
```

## Documentation

Documentation can be found at [https://hexdocs.pm/rrpproxy](https://hexdocs.pm/rrpproxy).
