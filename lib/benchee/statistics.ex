defmodule Benchee.Statistics do
  @moduledoc """
  Statistics related functionality that is meant to take the raw benchmark data
  and then compute statistics like the average and the standard deviation etc.

  See `statistics/1` for a breakdown of the included statistics.
  """

  alias Benchee.{CollectionData, Conversion.Duration, Scenario, Suite, Utility.Parallel}

  require Integer

  defstruct [
    :average,
    :ips,
    :std_dev,
    :std_dev_ratio,
    :std_dev_ips,
    :median,
    :percentiles,
    :mode,
    :minimum,
    :maximum,
    :relative_more,
    :relative_less,
    :absolute_difference,
    sample_size: 0
  ]

  @typedoc """
  Careful with the mode, might be multiple values, one value or nothing.😱
  """
  @type mode :: [number] | number | nil

  @typedoc """
  All the statistics `statistics/1` computes from the samples.

  Overview of all the statistics Benchee currently provides:

    * average       - average run time of the job in μs (the lower the better)
    * ips           - iterations per second, how often can the given function be
      executed within one second (the higher the better)
    * std_dev       - standard deviation, a measurement how much results vary
      (the higher the more the results vary)
    * std_dev_ratio - standard deviation expressed as how much it is relative to
      the average
    * std_dev_ips   - the absolute standard deviation of iterations per second
      (= ips * std_dev_ratio)
    * median        - when all measured times are sorted, this is the middle
      value (or average of the two middle values when the number of times is
      even). More stable than the average and somewhat more likely to be a
      typical value you see.
    * percentiles   - a map of percentile ranks. These are the values below
      which x% of the run times lie. For example, 99% of run times are shorter
      than the 99th percentile (99th %) rank.
      is a value for which 99% of the run times are shorter.
    * mode          - the run time(s) that occur the most. Often one value, but
      can be multiple values if they occur the same amount of times. If no value
      occurs at least twice, this value will be nil.
    * minimum       - the smallest sample measured for the scenario
    * maximum       - the biggest sample measured for the scenario
    * relative_more - relative to the reference (usually the fastest scenario) how much more
      was the average of this scenario. E.g. for reference at 100, this scenario 200 then it
      is 2.0.
    * relative_less - relative to the reference (usually the fastest scenario) how much less
      was the average of this scenario. E.g. for reference at 100, this scenario 200 then it
      is 0.5.
    * absolute_difference - relative to the reference (usually the fastest scenario) what is
      the difference of the averages of the scenarios. e.g. for reference at 100, this
      scenario 200 then it is 100.
    * sample_size   - the number of run time measurements taken
  """
  @type t :: %__MODULE__{
          average: float,
          ips: float | nil,
          std_dev: float,
          std_dev_ratio: float,
          std_dev_ips: float | nil,
          median: number,
          percentiles: %{number => float},
          mode: mode,
          minimum: number,
          maximum: number,
          relative_more: float | nil | :infinity,
          relative_less: float | nil | :infinity,
          absolute_difference: float | nil,
          sample_size: integer
        }

  @typedoc """
  The samples a `Benchee.Collect` collected to compute statistics from.
  """
  @type samples :: [number]

  @doc """
  Takes a suite with scenarios and their data samples, adds the statistics to the
  scenarios. For an overview of what the statistics mean see `t:t/0`.

  Note that this will also sort the scenarios fastest to slowest to ensure a consistent order
  of scenarios in all used formatters.

  ## Examples

      iex> scenarios = [
      ...>   %Benchee.Scenario{
      ...>     job_name: "My Job",
      ...>     run_time_data: %Benchee.CollectionData{
      ...>       samples: [200, 400, 400, 400, 500, 500, 500, 700, 900]
      ...>     },
      ...>     memory_usage_data: %Benchee.CollectionData{
      ...>       samples: [200, 400, 400, 400, 500, 500, 500, 700, 900]
      ...>     },
      ...>     input_name: "Input",
      ...>     input: "Input"
      ...>   }
      ...> ]
      iex> suite = %Benchee.Suite{scenarios: scenarios}
      iex> Benchee.Statistics.statistics(suite)
      %Benchee.Suite{
        scenarios: [
          %Benchee.Scenario{
            job_name: "My Job",
            input_name: "Input",
            input: "Input",
            run_time_data: %Benchee.CollectionData{
              samples: [200, 400, 400, 400, 500, 500, 500, 700, 900],
              statistics: %Benchee.Statistics{
                average:       500.0,
                ips:           2000_000.0,
                std_dev:       200.0,
                std_dev_ratio: 0.4,
                std_dev_ips:   800_000.0,
                median:        500.0,
                percentiles:   %{50 => 500.0, 99 => 900.0},
                mode:          [500, 400],
                minimum:       200,
                maximum:       900,
                sample_size:   9
              }
            },
            memory_usage_data: %Benchee.CollectionData{
              samples: [200, 400, 400, 400, 500, 500, 500, 700, 900],
              statistics: %Benchee.Statistics{
                average:       500.0,
                ips:           nil,
                std_dev:       200.0,
                std_dev_ratio: 0.4,
                std_dev_ips:   nil,
                median:        500.0,
                percentiles:   %{50 => 500.0, 99 => 900.0},
                mode:          [500, 400],
                minimum:       200,
                maximum:       900,
                sample_size:   9
              }
            }
          }
        ],
        system: nil
      }

  """
  @spec statistics(Suite.t()) :: Suite.t()
  def statistics(suite) do
    percentiles = suite.configuration.percentiles

    update_in(suite.scenarios, fn scenarios ->
      Parallel.map(scenarios, fn scenario ->
        calculate_scenario_statistics(scenario, percentiles)
      end)
    end)
  end

  defp calculate_scenario_statistics(scenario, percentiles) do
    run_time_stats =
      scenario.run_time_data.samples
      |> calculate_statistics(percentiles)
      |> add_ips

    memory_stats = calculate_statistics(scenario.memory_usage_data.samples, percentiles)
    reductions_stats = calculate_statistics(scenario.reductions_data.samples, percentiles)

    %Scenario{
      scenario
      | run_time_data: %CollectionData{
          scenario.run_time_data
          | statistics: run_time_stats
        },
        memory_usage_data: %CollectionData{
          scenario.memory_usage_data
          | statistics: memory_stats
        },
        reductions_data: %CollectionData{
          scenario.reductions_data
          | statistics: reductions_stats
        }
    }
  end

  defp calculate_statistics([], _) do
    %__MODULE__{
      sample_size: 0
    }
  end

  defp calculate_statistics(samples, percentiles) do
    samples
    |> Statistex.statistics(percentiles: percentiles)
    |> convert_from_statistex
  end

  defp convert_from_statistex(statistex_statistics) do
    %__MODULE__{
      average: statistex_statistics.average,
      std_dev: statistex_statistics.standard_deviation,
      std_dev_ratio: statistex_statistics.standard_deviation_ratio,
      median: statistex_statistics.median,
      percentiles: statistex_statistics.percentiles,
      mode: statistex_statistics.mode,
      minimum: statistex_statistics.minimum,
      maximum: statistex_statistics.maximum,
      sample_size: statistex_statistics.sample_size
    }
  end

  defp add_ips(statistics = %__MODULE__{sample_size: 0}), do: statistics
  defp add_ips(statistics = %__MODULE__{average: 0.0}), do: statistics

  defp add_ips(statistics) do
    ips = Duration.convert_value({1, :second}, :nanosecond) / statistics.average
    standard_dev_ips = ips * statistics.std_dev_ratio

    %__MODULE__{
      statistics
      | ips: ips,
        std_dev_ips: standard_dev_ips
    }
  end
end
