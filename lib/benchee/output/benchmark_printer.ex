defmodule Benchee.Output.BenchmarkPrinter do
  @moduledoc false

  alias Benchee.Conversion.Duration

  @doc """
  Shown when you try to define a benchmark with the same name twice.

  How would you want to discern those anyhow?
  """
  def duplicate_benchmark_warning(name) do
    IO.puts "You already have a job defined with the name \"#{name}\", you can't add two jobs with the same name!"
  end

  @doc """
  Prints general information such as system information and estimated
  benchmarking time.
  """
  def configuration_information(%{configuration: %{print: %{configuration: false}}}) do
    nil
  end
  def configuration_information(%{jobs: jobs, system: sys, configuration: config}) do
    system_information(sys)
    suite_information(jobs, config)
  end

  defp system_information(%{erlang: erlang_version,
                            elixir: elixir_version,
                            os: os,
                            num_cores: num_cores,
                            cpu_speed: cpu_speed,
                            available_memory: available_memory}) do
    IO.puts "Operating System: #{os}"
    IO.puts "CPU Information: #{cpu_speed}"
    IO.puts "Number of Available Cores: #{num_cores}"
    IO.puts "Available memory: #{available_memory}"
    IO.puts "Elixir #{elixir_version}"
    IO.puts "Erlang #{erlang_version}"
  end

  defp suite_information(jobs, %{parallel: parallel,
                                 time:     time,
                                 warmup:   warmup,
                                 inputs:   inputs}) do
    job_count      = map_size jobs
    exec_time      = warmup + time
    total_time     = job_count * inputs_count(inputs) * exec_time

    IO.puts """
    Benchmark suite executing with the following configuration:
    warmup: #{Duration.format(warmup)}
    time: #{Duration.format(time)}
    parallel: #{parallel}
    inputs: #{inputs_out(inputs)}
    Estimated total run time: #{Duration.format(total_time)}

    """
  end

  defp inputs_count(nil),    do: 1 # no input specified still executes
  defp inputs_count(inputs), do: map_size(inputs)

  defp inputs_out(nil), do: "none specified"
  defp inputs_out(inputs) do
    inputs
    |> Map.keys
    |> Enum.join(", ")
  end

  @doc """
  Prints a notice which job is currently being benchmarked.
  """
  def benchmarking(_, %{print: %{benchmarking: false}}), do: nil
  def benchmarking(name, _config) do
    IO.puts "Benchmarking #{name}..."
  end

  @doc """
  Prints a warning about accuracy of benchmarks when the function is super fast.
  """
  def fast_warning do
    IO.puts """
    Warning: The function you are trying to benchmark is super fast, making measures more unreliable! See: https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning

    You may disable this warning by passing print: [fast_warning: false] as configuration options.
    """
  end

  @doc """
  Prints an informative message about which input is currently being
  benchmarked, when multiple inputs were specified.
  """
  def input_information(_, %{print: %{benchmarking: false}}) do
    nil
  end
  def input_information(input_name, _config) do
    if input_name != Benchee.Benchmark.Runner.no_input() do
      IO.puts "\nBenchmarking with input #{input_name}:"
    end
  end

end
