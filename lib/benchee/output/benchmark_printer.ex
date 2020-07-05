defmodule Benchee.Output.BenchmarkPrinter do
  @moduledoc false

  alias Benchee.{Benchmark, Conversion.Duration}

  @doc """
  Shown when you try to define a benchmark with the same name twice.

  How would you want to discern those anyhow?
  """
  def duplicate_benchmark_warning(name) do
    IO.puts(
      "You already have a job defined with the name \"#{name}\", you can't add two jobs with the same name!"
    )
  end

  @doc """
  Prints general information about the system such as operating system.
  """
  def system_information(%{configuration: %{print: %{system: false}}}) do
    nil
  end

  def system_information(%{system: sys}) do
    print_system_information(sys)
  end

  defp print_system_information(%{
         erlang: erlang_version,
         elixir: elixir_version,
         os: os,
         num_cores: num_cores,
         cpu_speed: cpu_speed,
         available_memory: available_memory
       }) do
    IO.puts("""
    Operating System: #{os}
    CPU Information: #{cpu_speed}
    Number of Available Cores: #{num_cores}
    Available memory: #{available_memory}
    Elixir #{elixir_version}
    Erlang #{erlang_version}
    """)
  end

  @doc """
  Prints general benchmark information such as estimated benchmarking time.
  """
  def configuration_information(%{configuration: %{print: %{configuration: false}}}) do
    nil
  end

  def configuration_information(%{scenarios: scenarios, configuration: config}) do
    print_suite_information(scenarios, config)
  end

  defp print_suite_information(scenarios, %{
         parallel: parallel,
         time: time,
         warmup: warmup,
         inputs: inputs,
         memory_time: memory_time,
         reduction_time: reduction_time
       }) do
    scenario_count = length(scenarios)
    exec_time = warmup + time + memory_time + reduction_time
    total_time = scenario_count * exec_time

    IO.puts("""
    Benchmark suite executing with the following configuration:
    warmup: #{Duration.format(warmup)}
    time: #{Duration.format(time)}
    memory time: #{Duration.format(memory_time)}
    reduction time: #{Duration.format(reduction_time)}
    parallel: #{parallel}
    inputs: #{inputs_out(inputs)}
    Estimated total run time: #{Duration.format(total_time)}
    """)
  end

  defp inputs_out(nil), do: "none specified"

  defp inputs_out(inputs) do
    inputs
    |> Enum.map(fn {name, _} -> name end)
    |> Enum.join(", ")
  end

  @doc """
  Prints a notice which job is currently being benchmarked.
  """
  def benchmarking(_, _, %{print: %{benchmarking: false}}), do: nil

  def benchmarking(_, _, %{time: 0.0, warmup: 0.0, memory_time: 0.0, reduction_time: 0.0}),
    do: nil

  def benchmarking(name, input_name, _config) do
    IO.puts("Benchmarking #{name}#{input_information(input_name)}...")
  end

  @no_input Benchmark.no_input()
  defp input_information(@no_input), do: ""
  defp input_information(input_name), do: " with input #{input_name}"

  @doc """
  Prints a warning about accuracy of benchmarks when the function is super fast.
  """
  def fast_warning do
    IO.puts("""
    Warning: The function you are trying to benchmark is super fast, making measurements more unreliable!
    This holds especially true for memory measurements.
    See: https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning

    You may disable this warning by passing print: [fast_warning: false] as configuration options.
    """)
  end
end
