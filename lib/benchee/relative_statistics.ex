defmodule Benchee.RelativeStatistics do
  @moduledoc """
  Statistics that are relative from one scenario to another.

  Such as how much slower/faster something is or what the absolute difference is in the measured
  values.
  Is its own step because it has to be executed after scenarios have been loaded via
  `Benchee.ScenarioLoader` to include them in the calculation, while `Benchee.Statistics`
  has to happen before they are loaded to avoid recalculating their statistics.
  """

  alias Benchee.{Scenario, Statistics, Suite}

  @doc """
  Calculate the statistics of scenarios relative to each other and sorts scenarios.

  Such as `relative_more`, `relative_less` and `absolute_difference`,
  see `t:Benchee.Statistics.t/0` for more.

  The sorting of scenarios is important so that they always have the same order in
  all formatters. Scenarios are sorted first by run time average, then by memory average.
  """
  @spec relative_statistics(Suite.t()) :: Suite.t()
  def relative_statistics(suite) do
    scenarios =
      suite.scenarios
      |> sort()
      |> calculate_relative_statistics(suite.configuration.inputs)

    %Suite{suite | scenarios: scenarios}
  end

  defp calculate_relative_statistics([], _inputs), do: []

  defp calculate_relative_statistics(scenarios, inputs) do
    scenarios
    |> scenarios_by_input(inputs)
    |> Enum.flat_map(fn scenarios_with_same_input ->
      {reference, others} = split_reference_scenario(scenarios_with_same_input)
      others_with_relative = statistics_relative_to(others, reference)
      [reference | others_with_relative]
    end)
  end

  @spec sort([Scenario.t()]) :: [Scenario.t()]
  defp sort(scenarios) do
    Enum.sort_by(scenarios, fn scenario ->
      {scenario.run_time_data.statistics.average, scenario.memory_usage_data.statistics.average,
       scenario.reductions_data.statistics.average}
    end)
  end

  defp scenarios_by_input(scenarios, nil), do: [scenarios]

  # we can't just group_by `input_name` because that'd lose the order of inputs which might
  # be important
  defp scenarios_by_input(scenarios, inputs) do
    Enum.map(inputs, fn {input_name, _} ->
      Enum.filter(scenarios, fn scenario -> scenario.input_name == input_name end)
    end)
  end

  # right now we take the first scenario as we sorted them and it is the fastest,
  # whenever we implement #179 though this becomes more involved
  defp split_reference_scenario(scenarios) do
    [reference | others] = scenarios
    {reference, others}
  end

  defp statistics_relative_to(scenarios, reference) do
    Enum.map(scenarios, fn scenario ->
      scenario
      |> update_in([Access.key!(:run_time_data), Access.key!(:statistics)], fn statistics ->
        add_relative_statistics(statistics, reference.run_time_data.statistics)
      end)
      |> update_in([Access.key!(:memory_usage_data), Access.key!(:statistics)], fn statistics ->
        add_relative_statistics(statistics, reference.memory_usage_data.statistics)
      end)
      |> update_in([Access.key!(:reductions_data), Access.key!(:statistics)], fn statistics ->
        add_relative_statistics(statistics, reference.reductions_data.statistics)
      end)
    end)
  end

  # we might not run time/memory --> we shouldn't crash then ;)
  defp add_relative_statistics(statistics = %{average: nil}, _reference), do: statistics
  defp add_relative_statistics(statistics, %{average: nil}), do: statistics

  defp add_relative_statistics(statistics, reference_statistics) do
    %Statistics{
      statistics
      | relative_more: zero_safe_division(statistics.average, reference_statistics.average),
        relative_less: zero_safe_division(reference_statistics.average, statistics.average),
        absolute_difference: statistics.average - reference_statistics.average
    }
  end

  defp zero_safe_division(0.0, 0.0), do: 1.0
  defp zero_safe_division(_, 0), do: :infinity
  defp zero_safe_division(_, 0.0), do: :infinity
  defp zero_safe_division(a, b), do: a / b
end
