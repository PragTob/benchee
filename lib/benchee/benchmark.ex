defmodule Benchee.Benchmark do
  @moduledoc """
  Functions related to building and running benchmarking scenarios.
  Exposes `benchmark/4` and `collect/3` functions.
  """

  alias Benchee.Benchmark.{Runner, ScenarioContext}
  alias Benchee.Output.BenchmarkPrinter, as: Printer
  alias Benchee.Scenario
  alias Benchee.Suite
  alias Benchee.Utility.DeepConvert

  @no_input :__no_input

  @doc """
  Public access for the special key representing no input for a scenario.
  """
  def no_input, do: @no_input

  @doc """
  Takes the current suite and adds a new benchmarking scenario (represented by a
  %Scenario{} struct) with the given name and function to the suite's scenarios.
  If there are inputs in the suite's config, a scenario will be added for the given
  function for each input.
  """
  @spec benchmark(Suite.t(), Suite.key(), Scenario.benchmarking_function(), module) :: Suite.t()
  def benchmark(suite = %Suite{scenarios: scenarios}, job_name, function, printer \\ Printer) do
    normalized_name = to_string(job_name)

    if duplicate?(scenarios, normalized_name) do
      printer.duplicate_benchmark_warning(normalized_name)
      suite
    else
      add_scenario(suite, normalized_name, function)
    end
  end

  defp duplicate?(scenarios, job_name) do
    Enum.any?(scenarios, fn scenario -> scenario.name == job_name end)
  end

  defp add_scenario(
         suite = %Suite{scenarios: scenarios, configuration: config},
         job_name,
         function
       ) do
    new_scenarios = build_scenarios_for_job(job_name, function, config)
    %Suite{suite | scenarios: List.flatten([scenarios | new_scenarios])}
  end

  defp build_scenarios_for_job(job_name, function, %{inputs: nil}) do
    [
      build_scenario(%{
        job_name: job_name,
        function: function,
        input: @no_input,
        input_name: @no_input
      })
    ]
  end

  defp build_scenarios_for_job(job_name, function, %{inputs: inputs}) do
    Enum.map(inputs, fn {input_name, input} ->
      build_scenario(%{
        job_name: job_name,
        function: function,
        input: input,
        input_name: input_name
      })
    end)
  end

  defp build_scenario(scenario_data = %{function: {function, options}}) do
    scenario_data
    |> Map.put(:function, function)
    |> Map.merge(DeepConvert.to_map(options))
    |> build_scenario
  end

  defp build_scenario(scenario_data) do
    struct!(Scenario, add_scenario_name(scenario_data))
  end

  defp add_scenario_name(scenario_data) do
    Map.put(scenario_data, :name, Scenario.display_name(scenario_data))
  end

  @doc """
  Kicks off the benchmarking of all scenarios defined in the given suite.

  Hence, this might take a while ;) Passes a list of scenarios and a scenario context to our
  benchmark runner. For more information on how benchmarks are actually run, see the
  `Benchee.Benchmark.Runner` code (API considered private).
  """
  @spec collect(Suite.t(), module, module) :: Suite.t()
  def collect(
        suite = %Suite{scenarios: scenarios, configuration: config},
        printer \\ Printer,
        runner \\ Runner
      ) do
    printer.system_information(suite)
    printer.configuration_information(suite)
    scenario_context = %ScenarioContext{config: config, printer: printer}
    scenarios = runner.run_scenarios(scenarios, scenario_context)
    %Suite{suite | scenarios: scenarios}
  end

  # delegate use to Benchee.Project.Benchmark.__using__/1
  defmacro __using__(opts) do
    require Benchee.Project.Benchmark

    quoted =
      quote do
        use Benchee.Project.Benchmark, unquote(opts)
      end

    Macro.expand(quoted, __ENV__)
  end
end
