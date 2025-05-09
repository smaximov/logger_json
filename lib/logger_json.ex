defmodule LoggerJSON do
  @moduledoc """
  A collection of formatters and utilities for JSON-based logging for various cloud tools and platforms.

  ## Supported formatters

  * `LoggerJSON.Formatters.Basic` - a basic JSON formatter that logs messages in a structured format,
  can be used with any JSON-based logging system, like ElasticSearch, Logstash, etc.

  * `LoggerJSON.Formatters.GoogleCloud` - a formatter that logs messages in a structured format that can be
  consumed by Google Cloud Logger and Google Cloud Error Reporter.

  * `LoggerJSON.Formatters.Datadog` - a formatter that logs messages in a structured format that can be consumed
  by Datadog.

  * `LoggerJSON.Formatters.Elastic` - a formatter that logs messages in a structured format that conforms to the
  [Elastic Common Schema (ECS)](https://www.elastic.co/guide/en/ecs/8.11/ecs-reference.html),
  so it can be consumed by ElasticSearch, LogStash, FileBeat and Kibana.

  ## Installation

  Add `logger_json` to your list of dependencies in `mix.exs`:

      def deps do
        [
          # ...
          {:logger_json, "~> 7.0"}
          # ...
        ]
      end

  and install it running `mix deps.get`.

  Then, enable the formatter in your `runtime.exs`:

      config :logger, :default_handler,
        formatter: LoggerJSON.Formatters.Basic.new(metadata: [:request_id])

  or inside your application code (eg. in your `application.ex`):

      formatter = LoggerJSON.Formatters.Basic.new(metadata: :all)
      :logger.update_handler_config(:default, :formatter, formatter)

  or inside your `config.exs` (notice that `new/1` is not available here
  and tuple format must be used):

      config :logger, :default_handler,
        formatter: {LoggerJSON.Formatters.Basic, metadata: [:request_id]}

  ## Configuration

  Configuration can be set using `new/1` helper of the formatter module,
  or by setting the 2nd element of the `:formatter` option tuple in `Logger` configuration.

  For example in `config.exs`:

      config :logger, :default_handler,
        formatter: LoggerJSON.Formatters.GoogleCloud.new(metadata: :all, project_id: "logger-101")

  or during runtime:

      formatter = LoggerJSON.Formatters.Basic.new(metadata: {:all_except, [:conn]})
      :logger.update_handler_config(:default, :formatter, formatter)

  By default, `LoggerJSON` is using `Jason` as the JSON encoder. If you use Elixir 1.18 or later, you can
  use the built-in `JSON` module as the encoder. To do this, you need to set the `:encoder` option in your
  `config.exs` file. This setting is only available at compile-time:

      config :logger_json, encoder: JSON

  ### Shared Options

  Some formatters require additional configuration options. Here are the options that are common for each formatter:

    * `:encoder_opts` - options to be passed directly to the JSON encoder. This allows you to customize the behavior
    of the JSON encoder. If the encoder is `JSON`, it defaults to `JSON.protocol_encode/2`. Otherwise, defaults to
    empty keywords. See the [documentation for Jason](https://hexdocs.pm/jason/Jason.html#encode/2-options) for
    available options for `Jason` encoder.

    * `:metadata` - a list of metadata keys to include in the log entry. By default, no metadata is included.
    If `:all`is given, all metadata is included. If `{:all_except, keys}` is given, all metadata except
    the specified keys is included. If `{:from_application_env, {app, module}, path}` is given, the metadata is fetched from
    the application environment (eg. `{:from_application_env, {:logger, :default_formatter}, [:metadata]}`) during the
    configuration initialization.

    * `:redactors` - a list of tuples, where first element is the module that implements the `LoggerJSON.Redactor` behaviour,
    and the second element is the options to pass to the redactor module. By default, no redactors are used.

  ## Metadata

  You can set some well-known metadata keys to be included in the log entry. The following keys are supported
  for all formatters:

    * `:conn` - the `Plug.Conn` struct, setting it will include the request and response details in the log entry;
    * `:crash_reason` - a tuple where the first element is the exception struct and the second is the stacktrace.
    For example: `Logger.error("Exception!", crash_reason: {e, __STACKTRACE__})`. Setting it will include the exception
    details in the log entry.

  Formatters may encode the well-known metadata differently and support additional metadata keys, see the documentation
  of the formatter for more details.
  """

  # TODO: replace with `Logger.levels()` once LoggerJSON starts depending on Elixir 1.16+
  @log_levels [:error, :info, :debug, :emergency, :alert, :critical, :warning, :notice]
  @log_level_strings Enum.map(@log_levels, &to_string/1)

  @doc """
  Configures Logger log level at runtime by using value from environment variable.

  By default, 'LOG_LEVEL' environment variable is used.
  """
  def configure_log_level_from_env!(env_name \\ "LOG_LEVEL") do
    env_name
    |> System.get_env()
    |> configure_log_level!()
  end

  @doc """
  Changes Logger log level at runtime.

  Notice that settings this value below `compile_time_purge_level` would not work,
  because Logger calls would be already stripped at compile-time.
  """
  def configure_log_level!(nil),
    do: :ok

  def configure_log_level!(level) when level in @log_level_strings,
    do: Logger.configure(level: String.to_atom(level))

  def configure_log_level!(level) when level in @log_levels,
    do: Logger.configure(level: level)

  def configure_log_level!(level) do
    raise ArgumentError, "Log level should be one of #{inspect(@log_levels)} values, got: #{inspect(level)}"
  end
end
