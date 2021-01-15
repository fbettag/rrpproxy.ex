# RRPproxy

This package implements the [RRPproxy.net](https://rrpproxy.net) API for registering domains.

If you need more of their API, just launch a Pull Request.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `rrpproxy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rrpproxy, "~> 0.1.6"}
  ]
end
```

## Configuration

Put the following lines into your `config.exs` or better, into your environment
configuration files like `test.exs`, `dev.exs` or `prod.exs.`.

```elixir
config :rrpproxy,
  username: "yourlogin",
  password: "yourpassword",
  ote: true
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/rrpproxy](https://hexdocs.pm/rrpproxy).

