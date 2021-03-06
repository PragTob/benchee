defmodule Benchee.Configuration do
  @moduledoc """
  Functions to handle the configuration of Benchee, exposes `init/1` function.
  """

  alias Benchee.{
    Benchmark.Hooks,
    Configuration,
    Conversion.Duration,
    Conversion.Scale,
    Formatters.Console,
    Suite,
    Utility.DeepConvert
  }

  defstruct parallel: 1,
            time: 5,
            warmup: 2,
            memory_time: 0.0,
            reduction_time: 0.0,
            pre_check: false,
            formatters: [Console],
            percentiles: [50, 99],
            print: %{
              benchmarking: true,
              configuration: true,
              fast_warning: true
            },
            inputs: nil,
            save: false,
            load: false,
            unit_scaling: :best,
            # If you/your plugin/whatever needs it your data can go here
            assigns: %{},
            before_each: nil,
            after_each: nil,
            before_scenario: nil,
            after_scenario: nil,
            measure_function_call_overhead: true,
            title: nil,
            profile_after: false

  @typedoc """
  The configuration supplied by the user as either a map or a keyword list

  Possible options are:

  Possible options:

    * `warmup` - the time in seconds for which a benchmarking job should be run
    without measuring times before "real" measurements start. This simulates a
    _"warm"_ running system. Defaults to 2.
    * `time` - the time in seconds for how long each individual benchmarking job
    should be run for measuring the execution times (run time performance).
    Defaults to 5.
    * `memory_time` - the time in seconds for how long memory measurements
    should be conducted. Defaults to 0 (turned off).
    * `inputs` - a map from descriptive input names to some different input,
    your benchmarking jobs will then be run with each of these inputs. For this
    to work your benchmarking function gets the current input passed in as an
    argument into the function. Defaults to `nil`, aka no input specified and
    functions are called without an argument.
    * `title` - this option is purely cosmetic. If you would like to add a
    title with some meaning to a given suite, you can do so by providing
    a single string here. This is only for use by formatters.
    * `formatters` - list of formatters either as a module implementing the formatter
    behaviour, a tuple of said module and options it should take or formatter
    functions. They are run when using `Benchee.run/2` or you can invoktem them
    through `Benchee.Formatter.output/1`. Functions need to accept one argument (which
    is the benchmarking suite with all data) and then use that to produce output. Used
    for plugins. Defaults to the builtin console formatter
    `Benchee.Formatters.Console`. See [Formatters](#formatters).
    * `pre_check` - whether or not to run each job with each input - including all
    given before or after scenario or each hooks - before the benchmarks are
    measured to ensure that your code executes without error. This can save time
    while developing your suites. Defaults to `false`.
    * `parallel`   - each the function of each job will be executed in
    `parallel` number processes. If `parallel` is `4` then 4 processes will be
    spawned that all execute the _same_ function for the given time. When these
    finish/the time is up 4 new processes will be spawned for the next
    job/function. This gives you more data in the same time, but also puts a
    load on the system interfering with benchmark results. For more on the pros
    and cons of parallel benchmarking [check the
    wiki](https://github.com/PragTob/benchee/wiki/Parallel-Benchmarking).
    Defaults to 1 (no parallel execution).
    * `save` - specify a `path` where to store the results of the current
    benchmarking suite, tagged with the specified `tag`.
    * `load` - load saved suit or suits to compare your current benchmarks
    against. Can be a string or a list of strings or patterns.
    * `print` - a map from atoms to `true` or `false` to configure if the
    output identified by the atom will be printed. All options are enabled by
    default (true). Options are:
      * `:benchmarking`  - print when Benchee starts benchmarking a new job
      (Benchmarking name ..)
      * `:configuration` - a summary of configured benchmarking options
      including estimated total run time is printed before benchmarking starts
      * `:fast_warning`  - warnings are displayed if functions are executed
      too fast leading to inaccurate measures
    * `console` - options for the built-in console formatter:
      * `:comparison`   - if the comparison of the different benchmarking jobs
      (x times slower than) is shown (true/false). Enabled by default.
      * `extended_statistics` - display more statistics, aka `minimum`,
      `maximum`, `sample_size` and `mode`. Disabled by default.
    * `percentiles` - if you are using extended statistics and want to see the
    results for certain percentiles of results beyond just the median.
    Defaults to [50, 99] to calculate the 50th and 99th percentiles.
    * `:unit_scaling` - the strategy for choosing a unit for durations and
    counts. May or may not be implemented by a given formatter (The console
    formatter implements it). When scaling a value, Benchee finds the "best fit"
    unit (the largest unit for which the result is at least 1). For example,
    1_200_000 scales to `1.2 M`, while `800_000` scales to `800 K`. The
    `unit_scaling` strategy determines how Benchee chooses the best fit unit for
    an entire list of values, when the individual values in the list may have
    different best fit units. There are four strategies, defaulting to `:best`:
      * `:best`     - the most frequent best fit unit will be used, a tie
      will result in the larger unit being selected.
      * `:largest`  - the largest best fit unit will be used (i.e. thousand
      and seconds if values are large enough).
      * `:smallest` - the smallest best fit unit will be used (i.e.
      millisecond and one)
      * `:none`     - no unit scaling will occur. Durations will be displayed
      in microseconds, and counts will be displayed in ones (this is
      equivalent to the behaviour Benchee had pre 0.5.0)
    * `:before_scenario`/`after_scenario`/`before_each`/`after_each` - read up on them in the hooks section in the README
    * `:measure_function_call_overhead` - Measure how long an empty function call takes and deduct this from each measure run time. Defaults to true.
    * `profile_after` - accepts any of the following options:
      * a boolean   - `true` will enable profiling with the default profiler
      (`:eprof`) and `false` will disable profiling. Defaults to `false`.
      * a profiler  - either as a tuple of `{profiler, opts}` (e.g., `{:fprof, [sort: :own]}`)
      or just the profiler (e.g., `:fprof`), which is equivalent to `{profiler, []}`. The accepted built-in profilers are
      [`:cprof`](https://hexdocs.pm/mix/Mix.Tasks.Profile.Cprof.html),
      [`:eprof`](https://hexdocs.pm/mix/Mix.Tasks.Profile.Eprof.html) and
      [`:fprof`](https://hexdocs.pm/mix/Mix.Tasks.Profile.Fprof.html).
  """
  @type user_configuration :: map | keyword

  @typedoc """
  Generated configuration struct from the user supplied configuration options.

  Filled in with a lot of defaults. Also notably every option is already converted to
  a map or struct at this point for easier handling in Benchee.
  """
  @type t :: %__MODULE__{
          parallel: integer,
          time: number,
          warmup: number,
          memory_time: number,
          reduction_time: number,
          pre_check: boolean,
          formatters: [(Suite.t() -> Suite.t()) | module | {module, map}],
          print: map,
          inputs: %{Suite.key() => any} | [{Suite.key(), any}] | nil,
          save: map | false,
          load: String.t() | [String.t()] | false,
          unit_scaling: Scale.scaling_strategy(),
          assigns: map,
          before_each: Hooks.hook_function() | nil,
          after_each: Hooks.hook_function() | nil,
          before_scenario: Hooks.hook_function() | nil,
          after_scenario: Hooks.hook_function() | nil,
          measure_function_call_overhead: boolean,
          title: String.t() | nil,
          profile_after: boolean | atom | {atom, keyword}
        }

  @time_keys [:time, :warmup, :memory_time, :reduction_time]

  @doc """
  Returns the initial benchmark configuration for Benchee, composed of defaults
  and an optional custom configuration.

  Configuration times are given in seconds, but are converted to microseconds
  internally.

  For a list of all possible options see `t:user_configuration/0`

  ## Examples

      iex> Benchee.init
      %Benchee.Suite{
        configuration:
          %Benchee.Configuration{
            parallel: 1,
            time: 5_000_000_000.0,
            warmup: 2_000_000_000.0,
            inputs: nil,
            save: false,
            load: false,
            formatters: [Benchee.Formatters.Console],
            print: %{
              benchmarking: true,
              fast_warning: true,
              configuration: true
            },
            percentiles: [50, 99],
            unit_scaling: :best,
            assigns: %{},
            before_each: nil,
            after_each: nil,
            before_scenario: nil,
            after_scenario: nil
          },
        system: nil,
        scenarios: []
      }

      iex> Benchee.init time: 1, warmup: 0.2
      %Benchee.Suite{
        configuration:
          %Benchee.Configuration{
            parallel: 1,
            time: 1_000_000_000.0,
            warmup: 200_000_000.0,
            inputs: nil,
            save: false,
            load: false,
            formatters: [Benchee.Formatters.Console],
            print: %{
              benchmarking: true,
              fast_warning: true,
              configuration: true
            },
            percentiles: [50, 99],
            unit_scaling: :best,
            assigns: %{},
            before_each: nil,
            after_each: nil,
            before_scenario: nil,
            after_scenario: nil
          },
        system: nil,
        scenarios: []
      }

      iex> Benchee.init %{time: 1, warmup: 0.2}
      %Benchee.Suite{
        configuration:
          %Benchee.Configuration{
            parallel: 1,
            time: 1_000_000_000.0,
            warmup: 200_000_000.0,
            inputs: nil,
            save: false,
            load: false,
            formatters: [Benchee.Formatters.Console],
            print: %{
              benchmarking: true,
              fast_warning: true,
              configuration: true
            },
            percentiles: [50, 99],
            unit_scaling: :best,
            assigns: %{},
            before_each: nil,
            after_each: nil,
            before_scenario: nil,
            after_scenario: nil
          },
        system: nil,
        scenarios: []
      }

      iex> Benchee.init(
      ...>   parallel: 2,
      ...>   time: 1,
      ...>   warmup: 0.2,
      ...>   formatters: [&IO.puts/1],
      ...>   print: [fast_warning: false],
      ...>   inputs: %{"Small" => 5, "Big" => 9999},
      ...>   unit_scaling: :smallest)
      %Benchee.Suite{
        configuration:
          %Benchee.Configuration{
            parallel: 2,
            time: 1_000_000_000.0,
            warmup: 200_000_000.0,
            inputs: [{"Big", 9999}, {"Small", 5}],
            save: false,
            load: false,
            formatters: [&IO.puts/1],
            print: %{
              benchmarking: true,
              fast_warning: false,
              configuration: true
            },
            percentiles: [50, 99],
            unit_scaling: :smallest,
            assigns: %{},
            before_each: nil,
            after_each: nil,
            before_scenario: nil,
            after_scenario: nil
          },
        system: nil,
        scenarios: []
      }
  """
  @spec init(user_configuration) :: Suite.t()
  def init(config \\ %{}) do
    :ok = :timer.start()

    config =
      config
      |> standardized_user_configuration
      |> merge_with_defaults
      |> convert_time_to_nano_s
      |> save_option_conversion

    %Suite{configuration: config}
  end

  defp standardized_user_configuration(config) do
    config
    |> DeepConvert.to_map([:formatters, :inputs])
    |> standardize_inputs()
  end

  defp standardize_inputs(config = %{inputs: inputs}) do
    standardized_inputs =
      inputs
      |> Enum.reduce([], &standardize_inputs/2)
      |> Enum.reverse()

    %{config | inputs: standardized_inputs}
  end

  defp standardize_inputs(config), do: config

  defp standardize_inputs({name, value}, acc) do
    normalized_name = to_string(name)

    if List.keymember?(acc, normalized_name, 0) do
      acc
    else
      [{normalized_name, value} | acc]
    end
  end

  defp merge_with_defaults(user_config) do
    DeepMerge.deep_merge(%Configuration{}, user_config)
  end

  defp convert_time_to_nano_s(config) do
    Enum.reduce(@time_keys, config, fn key, new_config ->
      {_, new_config} =
        Map.get_and_update!(new_config, key, fn seconds ->
          {seconds, Duration.convert_value({seconds, :second}, :nanosecond)}
        end)

      new_config
    end)
  end

  defp save_option_conversion(config = %{save: false}), do: config

  defp save_option_conversion(config = %{save: save_values}) do
    save_options = Map.merge(save_defaults(), save_values)
    tagged_save_options = %{tag: save_options.tag, path: save_options.path}
    formatters = config.formatters ++ [{Benchee.Formatters.TaggedSave, tagged_save_options}]
    %__MODULE__{config | formatters: formatters}
  end

  defp save_defaults do
    now = DateTime.utc_now()

    %{
      tag: "#{now.year}-#{now.month}-#{now.day}--#{now.hour}-#{now.minute}-#{now.second}-utc",
      path: "benchmark.benchee"
    }
  end
end

defimpl DeepMerge.Resolver, for: Benchee.Configuration do
  def resolve(_original, override = %{__struct__: Benchee.Configuration}, _) do
    override
  end

  def resolve(original, override, resolver) when is_map(override) do
    merged = Map.merge(original, override, resolver)
    struct!(Benchee.Configuration, Map.to_list(merged))
  end
end
