defmodule Benchee.Suite do
  @moduledoc """
  Main Benchee data structure that aggregates the results from every step.

  Different layers of the benchmarking rely on different data being present
  here. For instance for `Benchee.Statistics.statistics/1` to work the
  `run_time_data` key of each scenario needs to be filled with the samples
  collected by `Benchee.Benchmark.collect/1`.

  Formatters can then use the data to display all of the results and the
  configuration.
  """
  defstruct [
    :system,
    configuration: %Benchee.Configuration{},
    scenarios: []
  ]

  @typedoc """
  Valid key for either input or benchmarking job names.
  """
  @type key :: String.t() | atom

  @typedoc """
  The main suite consisting of the configuration data, information about the system and most
  importantly a list of `t:Benchee.Scenario.t/0`.
  """
  @type t :: %__MODULE__{
          configuration: Benchee.Configuration.t() | nil,
          system: map | nil,
          scenarios: [] | [Benchee.Scenario.t()]
        }
end

defimpl DeepMerge.Resolver, for: Benchee.Suite do
  def resolve(original, override = %Benchee.Suite{}, resolver) do
    cleaned_override =
      override
      |> Map.from_struct()
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    Map.merge(original, cleaned_override, resolver)
  end

  def resolve(original, override, resolver) when is_map(override) do
    Map.merge(original, override, resolver)
  end
end
