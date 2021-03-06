defmodule Benchee.Conversion do
  @moduledoc """
  Integration of the conversion of multiple units with Benchee.

  Can be used by plugins to use Benchee unit scaling logic.
  """

  alias Benchee.Conversion.{Count, Duration, Memory}

  @doc """
  Takes scenarios and a given scaling_strategy, returns the best units for the
  given scaling strategy. The return value changes based on whether you want
  units for run time or memory usage.

  The units can then be passed on to the appropriate `format` calls to format
  the output of arbitrary values with the right unit.

  ## Examples

      iex> statistics = %Benchee.Statistics{average: 1_000_000.0, ips: 1000.0}
      iex> scenario = %Benchee.Scenario{
      ...>   run_time_data: %Benchee.CollectionData{statistics: statistics},
      ...>   memory_usage_data: %Benchee.CollectionData{statistics: statistics},
      ...>   reductions_data: %Benchee.CollectionData{statistics: statistics}
      ...> }
      iex> Benchee.Conversion.units([scenario], :best)
      %{
        ips:             %Benchee.Conversion.Unit{
                           label: "K",
                           long: "Thousand",
                           magnitude: 1000,
                           name: :thousand
                         },
        run_time:        %Benchee.Conversion.Unit{
                           label: "ms",
                           long: "Milliseconds",
                           magnitude: 1_000_000,
                           name: :millisecond
                         },
        memory:          %Benchee.Conversion.Unit{
                           label: "KB",
                           long: "Kilobytes",
                           magnitude: 1024,
                           name: :kilobyte
                         },
        reduction_count: %Benchee.Conversion.Unit{
                           label: "M",
                           long: "Million",
                           magnitude: 1000000,
                           name: :million
                         }
      }
  """
  def units(scenarios, scaling_strategy) do
    run_time_measurements = measurments_for(scenarios, :run_time_data)
    reductions_measurements = measurments_for(scenarios, :reductions_data)
    memory_measurements = measurments_for(scenarios, :memory_usage_data)

    %{
      run_time: Duration.best(run_time_measurements.average, strategy: scaling_strategy),
      ips: Count.best(run_time_measurements.ips, strategy: scaling_strategy),
      memory: Memory.best(memory_measurements.average, strategy: scaling_strategy),
      reduction_count: Count.best(reductions_measurements.average, strategry: scaling_strategy)
    }
  end

  defp measurments_for(scenarios, path) do
    paths = [Access.key(path), Access.key(:statistics)]

    scenarios
    |> Enum.flat_map(fn scenario -> scenario |> get_in(paths) |> Map.to_list() end)
    |> Enum.group_by(fn {stat_name, _} -> stat_name end, fn {_, value} -> value end)
  end
end
