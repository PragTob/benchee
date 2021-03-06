defmodule Benchee.Formatters.TaggedSave do
  @moduledoc """
  Store the whole suite in the Erlang `ExternalTermFormat` while tagging the
  scenarios of the current run with a specified tag - can be used for storing
  and later loading the results of previous runs with `Benchee.ScenarioLoader`.

  Automatically configured as the last formatter to run when specifying the
  `save` option in the configuration - see `Benchee.Configuration`.
  """

  @behaviour Benchee.Formatter

  alias Benchee.Scenario
  alias Benchee.Suite
  alias Benchee.Utility.FileCreation

  @doc """
  Tags all scenario with the desired tag and returns it in term_to_binary along with save path.
  """
  @impl true
  @spec format(Suite.t(), map) :: {binary, String.t()}
  def format(suite = %Suite{scenarios: scenarios}, formatter_config) do
    tag = determine_tag(scenarios, formatter_config)
    tagged_scenarios = tag_scenarios(scenarios, tag)
    tagged_suite = %Suite{suite | scenarios: tagged_scenarios}

    {:erlang.term_to_binary(tagged_suite), formatter_config.path}
  end

  defp determine_tag(scenarios, %{tag: desired_tag}) do
    scenarios
    |> Enum.map(fn scenario -> scenario.tag end)
    |> Enum.uniq()
    |> Enum.filter(fn tag ->
      tag != nil && tag =~ ~r/#{Regex.escape(desired_tag)}/
    end)
    |> choose_tag(desired_tag)
  end

  defp choose_tag([], desired_tag), do: desired_tag

  defp choose_tag(tags, desired_tag) do
    max = get_maximum_tag_increaser(tags, desired_tag)
    "#{desired_tag}-#{max + 1}"
  end

  defp get_maximum_tag_increaser(tags, desired_tag) do
    tags
    |> Enum.map(fn tag -> String.replace(tag, ~r/#{Regex.escape(desired_tag)}-?/, "") end)
    |> Enum.map(&tag_increaser/1)
    |> Enum.max()
  end

  defp tag_increaser(""), do: 1
  defp tag_increaser(string_number), do: String.to_integer(string_number)

  defp tag_scenarios(scenarios, tag) do
    Enum.map(scenarios, fn scenario ->
      scenario
      |> tagged_scenario(tag)
      |> update_name
    end)
  end

  defp tagged_scenario(scenario = %Scenario{tag: nil}, desired_tag) do
    %Scenario{scenario | tag: desired_tag}
  end

  defp tagged_scenario(scenario, _desired_tag) do
    scenario
  end

  defp update_name(scenario) do
    %Scenario{scenario | name: Scenario.display_name(scenario)}
  end

  @doc """
  Writes the binary returned by `format/2` to the indicated location, telling you where that is.
  """
  @spec write({binary, String.t()}, map) :: :ok
  @impl true
  def write({term_binary, filename}, _) do
    FileCreation.ensure_directory_exists(filename)
    return_value = File.write(filename, term_binary)

    IO.puts("Suite saved in external term format at #{filename}")

    return_value
  end
end
