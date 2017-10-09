defmodule Benchee.Statistics do
  @moduledoc """
  Statistics related functionality that is meant to take the raw benchmark run
  times and then compute statistics like the average and the standard devaition.
  """

  alias Benchee.Statistics.Mode

  defstruct [
    :average,
    :ips,
    :std_dev,
    :std_dev_ratio,
    :std_dev_ips,
    :median,
    :mode,
    :minimum,
    :maximum,
    :sample_size
  ]

  @type t :: %__MODULE__{
          average: float,
          ips: float,
          std_dev: float,
          std_dev_ratio: float,
          std_dev_ips: float,
          median: number,
          mode: number,
          minimum: number,
          maximum: number,
          sample_size: integer
        }

  @type samples :: [number]

  alias Benchee.{Statistics, Conversion.Duration, Suite, Benchmark.Scenario, Utility.Parallel}
  require Integer

  @doc """
  Sorts the given scenarios fastest to slowest by run_time average.

  ## Examples

      iex> scenario_1 = %Benchee.Benchmark.Scenario{run_time_statistics: %Statistics{average: 100.0}}
      iex> scenario_2 = %Benchee.Benchmark.Scenario{run_time_statistics: %Statistics{average: 200.0}}
      iex> scenario_3 = %Benchee.Benchmark.Scenario{run_time_statistics: %Statistics{average: 400.0}}
      iex> scenarios = [scenario_2, scenario_3, scenario_1]
      iex> Benchee.Statistics.sort(scenarios)
      [%Benchee.Benchmark.Scenario{run_time_statistics: %Statistics{average: 100.0}},
       %Benchee.Benchmark.Scenario{run_time_statistics: %Statistics{average: 200.0}},
       %Benchee.Benchmark.Scenario{run_time_statistics: %Statistics{average: 400.0}}]
  """
  @spec sort([%Scenario{}]) :: [%Scenario{}]
  def sort(scenarios) do
    Enum.sort_by(scenarios, fn %Scenario{run_time_statistics: %Statistics{average: average}} ->
      average
    end)
  end

  @doc """
  Takes a job suite with job run times, returns a map representing the
  statistics of the job suite as follows:

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
      typical you see.
    * mode          - the run time(s) that occur the most. Often one value, but
      can be multiple values if they occur the same amount of times. If no value
      occures at least twice, this value will be nil.
    * minimum       - the smallest (fastest) run time measured for the job
    * maximum       - the biggest (slowest) run time measured for the job
    * sample_size   - the number of run time measurements taken

  ## Parameters

  * `suite` - the job suite represented as a map after running the measurements,
    required to have the run_times available under the `run_times` key

  ## Examples

      iex> scenarios = [
      ...>   %Benchee.Benchmark.Scenario{
      ...>     job_name: "My Job",
      ...>     run_times: [200, 400, 400, 400, 500, 500, 700, 900],
      ...>     input_name: "Input",
      ...>     input: "Input"
      ...>   }
      ...> ]
      iex> suite = %Benchee.Suite{scenarios: scenarios}
      iex> Benchee.Statistics.statistics(suite)
      %Benchee.Suite{
        scenarios: [
          %Benchee.Benchmark.Scenario{
            job_name: "My Job",
            run_times: [200, 400, 400, 400, 500, 500, 700, 900],
            input_name: "Input",
            input: "Input",
            run_time_statistics: %Benchee.Statistics{
              average:       500.0,
              ips:           2000.0,
              std_dev:       200.0,
              std_dev_ratio: 0.4,
              std_dev_ips:   800.0,
              median:        450.0,
              mode:          400,
              minimum:       200,
              maximum:       900,
              sample_size:   8
            }
          }
        ],
        configuration: nil,
        system: nil
      }

  """
  @spec statistics(Suite.t()) :: Suite.t()
  def statistics(suite = %Suite{scenarios: scenarios}) do
    new_scenarios =
      Parallel.map(scenarios, fn scenario ->
        stats = job_statistics(scenario.run_times)
        %Scenario{scenario | run_time_statistics: stats}
      end)

    %Suite{suite | scenarios: new_scenarios}
  end

  @doc """
  Calculates statistical data based on a series of run times for a job
  in microseconds.

  ## Examples

      iex> run_times = [200, 400, 400, 400, 500, 500, 700, 900]
      iex> Benchee.Statistics.job_statistics(run_times)
      %Benchee.Statistics{
        average:       500.0,
        ips:           2000.0,
        std_dev:       200.0,
        std_dev_ratio: 0.4,
        std_dev_ips:   800.0,
        median:        450.0,
        mode:          400,
        minimum:       200,
        maximum:       900,
        sample_size:   8
      }

  """
  @spec job_statistics(samples) :: __MODULE__.t()
  def job_statistics(run_times) do
    total_time = Enum.sum(run_times)
    iterations = Enum.count(run_times)
    average = total_time / iterations
    ips = iterations_per_second(average)
    deviation = standard_deviation(run_times, average, iterations)
    standard_dev_ratio = deviation / average
    standard_dev_ips = ips * standard_dev_ratio
    median = compute_median(run_times, iterations)
    mode = Mode.mode(run_times)
    minimum = Enum.min(run_times)
    maximum = Enum.max(run_times)

    %__MODULE__{
      average: average,
      ips: ips,
      std_dev: deviation,
      std_dev_ratio: standard_dev_ratio,
      std_dev_ips: standard_dev_ips,
      median: median,
      mode: mode,
      minimum: minimum,
      maximum: maximum,
      sample_size: iterations
    }
  end

  defp iterations_per_second(average_microseconds) do
    Duration.microseconds({1, :second}) / average_microseconds
  end

  defp standard_deviation(samples, average, iterations) do
    total_variance =
      Enum.reduce(samples, 0, fn sample, total -> total + :math.pow(sample - average, 2) end)

    variance = total_variance / iterations
    :math.sqrt(variance)
  end

  defp compute_median(run_times, iterations) do
    # this is rather inefficient, as O(log(n) * n + n) - there are
    # O(n) algorithms to do compute this should it get to be a problem.
    sorted = Enum.sort(run_times)
    middle = div(iterations, 2)

    if Integer.is_odd(iterations) do
      sorted |> Enum.at(middle) |> to_float
    else
      (Enum.at(sorted, middle) + Enum.at(sorted, middle - 1)) / 2
    end
  end

  defp to_float(maybe_integer) do
    :erlang.float(maybe_integer)
  end
end
