defmodule Clickhouse.Benchmark.Performance do
  use Benchee.Benchmark

  # Since it's a module, any other constructs may be used,
  # such as defs, defmacro, etc.
  def map_fun(i) do
    [i]
  end

  # Global benchmark setup. Optional.
  #
  # Called before any benchmark in the module.
  #
  # If defined, must return {:ok, state} for benchmarks to run
  before_all do
    {:ok, nil}
  end

  # Global benchmark teardown. Optional.
  #
  # Called after all benchmarks have finished
  # (and their possible local teardowns had been called).
  #
  # Can return anything.
  after_all do
    :anything
  end

  # Benchmarks. Module may have many of them.
  benchmark "Flattening list from map", # Name. Mandatory.
  warmup: 0, time: 1          # Opts (see Benchee.run). Optional.
    do                                  # Do block. Mandatory.

    # Benchmark setup. Optional
    #
    # If global setup is defined,
    # implicit variable "state" is bound to it's result
    #
    # If defined, must return {:ok, state} for benchmarks to run
    before_benchmark do
      {:ok, fn x -> [x] end}
    end

    # Benchmark teardown. Optional
    #
    # Implicit variable: state, as it is returned from local setup
    # (or from global setup, if no local setup is defined)
    #
    # Can return anything
    after_benchmark do
      :anything
    end

    # Inputs: the same as passing inputs via :input option
    #
    # Accepts either an expression or a do block as a 2nd argument
    input "Small", Enum.to_list(1..100)
    input "Medium" do
      n = 10_000
      Enum.to_list(1..n)
    end
    input "Bigger", Enum.to_list(1..100_000)


    # Benchmark scenarios
    #
    # Each scenario has an implicit variables:
    # - state: state returned from local or global setup
    # And if any input is passed (either with option or as input directive):
    # - input: data for benchmark
    scenario "Enum.flat_map", # Name. Mandatory
      before_scenario:
        fn i ->               # Scenario options, e.g. local hooks. Optional.
          IO.inspect(length(i), label: "Input length");
          i
        end
      do                      # Do block. Mandatory
        map_fun = state
        Enum.flat_map(input, map_fun)
      end

    scenario "Enum.map |> List.flatten" do
      map_fun = state
      input |> Enum.map(map_fun) |> List.flatten()
    end
  end
end
