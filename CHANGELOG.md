# Changelog

## 1.0.1 (2019-04-09)

### Bugfixes (User Facing)
* When memory measurements were actually different extended statistics was displayed although the option was not provided. Now correctly only displayed if the option is provided and values actually had variance.

## 1.0.0 (2019-03-28)

It's 0.99.0 without the deprecation warnings. Specifically:

* Old way of passing formatters (`:formatter_options`) vs. new `:formatters` with modules, tuples or functions with one arg
* The configuration needs to be passed as the second argument to `Benchee.run/2`
* `Benchee.collect/1` replaces `Benchee.measure/1`
* `unit_scaling` is a top level configuration option, not for the console formatter
* the warning for memory measurements not working on OTP <= 18 will also be dropped (we already officially dropped OTP 18 support in 0.14.0)

We're aiming to follow Semantic Versioning as we go forward. That means formatters should be safe to use `~> 1.0` (or even `>= 0.99.0 and < 2.0.0`).

## 0.99.0 (2019-03-28)

The "we're almost 1.0!" release - all the last small features, a bag of polish and deprecation warnings. If you run this release successfully without deprecation warnings you should be safe to upgrade to 1.0.0, if not - it's a bug :)

### Breaking Changes (User Facing)
* changed official Elixir compatibility to `~> 1.6`, 1.4+ should still work but aren't guaranteed or tested against.

### Features (User Facing)
* the console comparison now also displays the absolute difference in the average (like +12 ms) so that you have an idea to how much time that translates to in your applications not just that it's 100x faster
* Overhaul of README, documentation, update samples etc. - a whole lot of things have also been marked `@doc false` as they're considered internal

### Bugfixes (User Facing)
* Remove double empty line after configuration display
* Fix some wrong type specs

### Breaking Changes (Plugins)
* `Scenario` made it to the big leagues, it's no longer `Benchee.Benchmark.Scenario` but `Benchee.Scenario` - as it is arguably one of our most important data structures.
* The `Scenario` struct had some keys changed (last time before 2.0 I promise!) - instead of `:run_times`/`:run_time_statistics` you now have one `run_time_data` key that contains `Benchee.CollectionData` which has the keys `:samples` and `:statistics`. Same for `memory_usage`. This was done to be able to handle different kinds of measurements more uniformly as we will add more of them.

### Features (Plugins)
* `Benchee.Statistics` comes with 3 new values: `:relative_more`, `:relative_less`, `:absolute_difference` so that you don't have to calculate these relative values yourself :)

## 0.14.0 (2019-02-10)

Highlights of this release are a new way to specify formatter options closer to the formatters themselves as well as maximum precision measurements.

### Breaking Changes (User Facing)
* dropped support for Erlang 18.x
* Formatters no longer have an `output/1` method, instead use `Formatter.output/3` please
* Usage of `formatter_options` is deprecated, instead please use the new tuple way

### Features (User Facing)
* Benchee now uses the maximum precision available to measure which on Linux and OSX is nanoseonds instead of microseconds. Somewhat surprisingly `:timer.tc/1` always cut down to microseconds although better precision is available.
* The preferred way to specify formatters and their options is to specify them as a tuple `{module, options}` instead of using `formatter_options`.
* New `Formatter.output/1` function that takes a suite and uses all configured formatters to output their results
* Add the concept of a benchmarking title that formatters can pick up
* the displayed percentiles can now be adjusted
* inputs option can now be an ordered list of tuples, this way you can determine their order
* support FreeBSD properly (system metrics) - thanks @[kimshrier](/kimshrier)

### Bugfixes (User Facing)
* Remove extra double quotes in operating system report line - thanks @[kimshrier](/kimshrier)

### Breaking Changes (Plugins)
* all reported times are now in nanoseconds instead of microseconds
* formatter methods `format` and `write` now take 2 arguments each where the additional arguments is the options specified for this formatter so that you have direct access to it without peeling it from the suite
* You can no longer `use Benchee.Formatter` - just adopt the behaviour (no more auto generated `output/1` method, but `Formatter.output/3` takes that responsibility now)

### Features (Plugins)
* An optional title is now available in the suite for you to display
* Scenarios are now sorted already sorted (first by run time, then memory usage) - no need to sort them yourself!
* Add `Scenario.data_processed?/2` to check if either run time or memory data has had statistics generated

## 0.13.2 (2018-08-02)

Mostly fixing memory measurement bugs and delivering them to you asap ;)

### Bugfixes (User Facing)
* Remove race condition that caused us to sometimes miss garbage collection events and hence report even negative or N/A results
* restructure measuring code to produce less overhead (micro memory benchmarks should be much better now)
* make console formatter more resilient to faulty memory measurements aka don't crash

## 0.13.1 (2018-05-02)

Mostly fixing memory measurement bugs and related issues :) Enjoy a better memory measurement experience from now on!

### Bugfixes (User Facing)
* Memory measurements now correctly take the old generation on the heap into account. In reality that means sometimes bigger results and no missing measurements. See [#216](https://github.com/PragTob/benchee/pull/216) for details. Thanks to @michalmuskala for providing an interesting sample.
* Formatters are now more robust (aka not crashing) when dealing with partially missing memory measurements. Although it shouldn't happen anymore with the item before fixed, Benchee shouldn't crash on you so we want to be on the safe side.
* It's now possible to run just memory measurements (i.e. `time: 0, warmup: 0, memory_time: 1`)
* even when you already have scenarios tagged with `-2` etc. it still correctly produces `-3`, `-4` etc. when saving again with the same "base tage name"

## 0.13.0 (2018-04-14)

Memory Measurements are finally here! Please report problems if you experience them.

### Features (User Facing)
* Memory measurements obviously ;) Memory measurement are currently limited to process your function will be run in - memory consumption of other processes will **not** be measured. More information can be found in the [README](https://github.com/PragTob/benchee#measuring-memory-consumption). Only usable on OTP 19+. Special thanks go to @devonestes and @michalmuskala
* new `pre_check` configuration option which allows users to add a dry run of all
benchmarks with each input before running the actual suite. This should save
time while actually writing the code for your benchmarks.

### Bugfixes (User Facing)
* Standard Deviation is now calculated correctly for being a sample of the population (divided by `n - 1` and not just `n`)

## 0.12.1 (2018-02-26)

### Bugfixes (User Facing)
* Formatters that use `FileCreation.each` will no longer silently fail on file
creation and now also sanitizes `/` and other file name characters to be `_`.
Thanks @gfvcastro

## 0.12.0 (2018-01-20)

Adds the ability to save benchmarking results and load them again to compare
against. Also fixes a bug for running benchmarks in parallel.

### Breaking Changes (User Facing)
* Dropped Support for elixir 1.3, new support is elixir 1.4+

### Features (User Facing)
* new `save` option specifying a path and a tag to save the results and tag them
(for instance with `"master"`) and a `load` option to load those results again
and compare them against your current results.
* runs warning free with elixir 1.6

### Bugfixes (User Facing)

* If you were running benchmarks in parallel, you would see results for each
parallel process you were running. So, if you were running **two** jobs, and
setting your configuration to `parallel: 2`, you would see **four** results in the
formatter. This is now correctly showing only the **two** jobs.

### Features (Plugins)
* `Scenario` has a new `name` field to be adopted for displaying the scenario names,
as it includes the tag name and potential future additions.

## 0.11.0 (2017-11-30)

A tiny little release with a bugfix and MOARE statistics for the console formatter.

### Bugfixes (User Facing)

* estimated run times should be correct again, they were too high when inputs were used

### Features (User Facing)

* the console formatter accepts a new `extended_statistics` options that shows you additional statistics such as `minimum`, `maximum`, `sample_size` and the `mode`. Thanks `@lwalter`

## 0.10.0 (2017-10-24)

This release focuses on 2 main things: the internal restructuring to use _scenarios_ and the new _hooks_ system. Other than that we also have some nice convenience features and formatters can be generated in parallel now.

### Features (User Facing)
* Hooks system - basically you can now do something before/after a benchmarking scenario or the benchmarking function, too much to explain it in a Changelog, check the [README](https://github.com/PragTob/benchee#hooks-setup-teardown-etc)
* Don't show more precision than we have - i.e. 234.00 microseconds (measurements are in microseconds and .00 doesn't gain you anything)
* Limit precision of available memory displayed, you don't need to know 7.45678932 GB. Thanks to `@elpikel`.
* Display the 99th percentile runtime. Thanks to `@wasnotrice`.
* `:unit_scaling` is now a top level configuration option that can now also be used and picked up by formatters, like the HTML formatter
* formatters can now be specified as a module (which should implement the `Benchee.Formatter` behaviour) - this makes specifying them nice and now at least their `format/1` functions can be executed in parallel

### Bugfixes (User Facing)
* Determining CPUs was too strict/too assuming of a specific pattern breaking in certain environments (like Semaphore CI). That is more relaxed now thanks to `@predrag-rakic`!
* Memory is now correctly converted using the binary (1024) interpretation, instead of the decimal one (1000)


### Features (Plugins)
* the statistics now also provide the mode of the samples as well as the 99th percentile
* There is a new `Benchee.Formatter` behaviour to adopt and enforce a uniform format for formatters, best to do `use Benchee.Formatter`

### Breaking Changes (Plugins)
* `:run_times`, `:statistics` and `:jobs` have been removed and folded together into `:scenarios` - a scenario holds the benchmarking function, potentially the input, the raw run times measures and the computed statistics. With this data structure, all the relevant data for one scenario is one place although it takes a lot to change, this seems to be the best way going forward. Huge thanks to `@devonestes`!

## 0.9.0 (2017-06-08)

This release focuses on adding more system specific information like CPU etc. and for better Erlang compatibility if you wanna use Benchee from Erlang. There is an [example project](https://github.com/PragTob/benchee_erlang_try) but calling Elixir from Erlang hasn't been as easy as I hoped :)

### Features (User Facing)
* Gather more system data like number of cores, Operating System, memory, cpu speed - thanks @devonestes and @OvermindDL1
* the names for jobs in the map of `Benchee.run/2` or in `Benchee.benchmark/3` may now be given as strings or atoms - atoms will be converted to strings internally though for consistency and avoiding name duplicates
* the names of inputs in the Benchee configuration may now be given as strings or atoms - atoms will be converted to strings internally though for consistency and avoiding name duplicates
* Benchee is now also available _"Erlang Style"_ to be called on an atom like `:benchee.run(_, _)` for better Erlang compatibility

## 0.8.0 (2017-05-07)

Another smaller release that focuses on adding type specs and structs in appropriate places along with fixing a couple of small bugs.

### Features (User Facing)
* Providing an unrecognized configuration option (say `runNtime` instead of `runtime`) will now raise an exception
* Durations in the configuration will now be scaled appropriately (minutes, microseconds etc)
* Major functions are type specced for your viewing pleasure in the docs and your dialyzer pleasure at type check time.

### Bugfixes (User Facing)
* In 0.7.0 statistics generation might time out if Millions of run times were captured so that it takes longer than 5 seconds, this is fixed by waiting infinitely - thanks @devonestes for the [report](https://github.com/PragTob/benchee/issues/71).
* Unintended line break in the fast function warning removed
* All necessary dependencies added to `:applications` (deep_merge was missing)

### Breaking Changes (User Facing)
* Dropped support for elixir 1.2, new support is elixir 1.3+
* `Benchee.Config` was renamed to `Benchee.Configuration` (important when you use the more verbose API or used it in a Plugin)

### Features (Plugins)
* Major public interfacing functions are now typespecced!
* A couple of major data structures are now proper structs e.g. `Benchee.Suite`, `Benchee.Configuration`, `Benchee.Statistics`

### Breaking Changes (Plugins)
* The `config` key is now `configuration` to go along with the Configuration name change
* As `Benchee.Configuration` is a proper struct now, arbitrary keys don't end up in it anymore. Custom data for plugins should be passed in through `formatter_options` or `assigns`. Existing plugin keys (`csv`, `json`, `html` and `console`) are automatically put into the `formatter_options` key space for now.

## 0.7.0 (April 23, 2017)

Smaller convenience features in here - the biggest part of work went into breaking reports in [benchee_html](https://github.com/PragTob/benchee_html) apart :)

### Features (User Facing)
* the print out of the Erlang version now is less verbose (just major/minor)
* the fast_warning will now also tell you how to disable it
* When `print: [benchmarking: false]` is set, information about which input is being benchmarked at the moment also won't be printed
* generation of statistics parallelized (thanks hh.ex - @nesQuick and @dszam)

### Breaking Changes (User Facing)
* If you use the more verbose interface (`Benchee.init` and friends, e.g. not `Benchee.run`) then you have to insert a `Benchee.system` call before `Benchee.measure` (preferably right after `Benchee.init`)

### Features (Plugins)
* `Benchee.Utility.FileCreation.interleave/2` now also accepts a list of inputs which are then all interleaved in the file name appropriately. See the doctests for more details.

### Breaking Changes (Plugins)
* `Benchee.measure/1` now also needs to have the system information generated by `Benchee.system/1` present if configuration information should be printed.

## 0.6.0 (November 30, 2016)

One of the biggest releases yet. Great stuff in here - more elixir like API for `Benchee.run/2` with the jobs as the primary argument and the optional options as the second argument and now also as the more idiomatic keyword list!

The biggest feature apart from that is the possibility to use multiple inputs - which you all should do now as quite many functions behave differently with bigger, smaller or differently shaped inputs. Apart from that a bulk of work has gone into making and supporting [benchee_html](https://github.com/PragTob/benchee_html)!

### Features (User Facing)

* New `:inputs` configuration key that allows you to specify a map from input name to input value so that each defined benchmarking job is then executed with this input. For this to work the benchmarking function is called with the appropriate `input` as an argument. See [`samples/multiple_inputs.exs`](https://github.com/PragTob/benchee/blob/master/samples/multiple_inputs.exs) for an example. [#21]( https://github.com/PragTob/benchee/issues/21)
* The highlevel `Benchee.run/2` is now more idiomatic elixir and takes the map of jobs as the first argument and a keyword list of options as the second (and last) argument. The old way of passing config as a map as the first argument and the jobs as the second argument still works, **but might be deprecated later on** [#47](https://github.com/PragTob/benchee/issues/47)
* Along with that `Benchee.init/1` now also accepts keyword lists of course

### Breaking Changes (User Facing)

* The old way of providing the jobs as a list of tuples now removed, please switch to using a map from string to functions

### Features (Plugins)

* `Benchee.Utility.FileCreation` module to help with creating files from a map of multiple inputs (or other descriptors) mapping to input and an `interleave` function that spits out the correct file names especially if the `:__no_input` marker is used
* `Benchee.System` is available to retrieve Elixir and Erlang versions but it's
also already added to the suite during `Benchee.run/2`

### Breaking Changes (Plugins)

* The structure of the output from `Benchee.Benchmark.measure/1` to `Benchee.Statistics.statistics/1` has changed to accommodate the new inputs feature there is now an additional level where in a map the input name then points to the appropriate results of the jobs. When there were no inputs the key is the value returned by `Benchee.Benchmark.no_input/0`.

### Bugfixes

* prewarming (discarding the first result due to some timer issues) during run time was removed, as it should already happen during the warmup period and would discard actual useful results especially for longer running macro benchmarks.
* when the execution time of the benchmarking job exceeds the given `:time` it will now execute exactly once (used to be 2) [#49](https://github.com/PragTob/benchee/issues/49)
* `run_times` are now in the order as recorded (used to be reverse) - important when wants to graph them/look at them to see if there are any anomalies during benchmarking
* Remove elixir 1.4.0-rc.0 warnings

## 0.5.0 (October 13, 2016)

This release focuses on scaling units to more appropriate sizes. Instead of always working with base one for counts and microseconds those values are scaled accordingly to thousands, milliseconds for better readability. This work was mostly done by new contributor @wasnotrice.

### Features (User Facing)

* Console output now scales units to be more friendly. Examples:
    * instead of "44556677" ips, you would see "44.56 M"
    * instead of "44556.77 μs" run time, you would see "44.56 ms"
* Console output for standard deviation omits the parentheses
* Scaling of console output can be configured with the 4 different strategies `:best`, `:largest`, `:smallest` and `:none`. Refer to the documentation for their different properties.
* Shortened the fast function warning and instead [linked to the wiki](https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning)

### Features (Plugins)

* The statistics module now computes the `minimum`, `maximum` and `sample_size` (not yet shown in the console formatter)
* you can rely on `Benchee.Conversion.Duration`, `Benchee.Conversion.Count` and `Benchee.Conversion.DeviationPercent` for help with formatting and scaling units

### Breaking Changes (Plugins)

* The `Benchee.Time`module is gone, if you relied on it for one reason or another it's succeeded by the more powerful `Benchee.Conversion.Duration`

## 0.4.0 (September 11, 2016)

Focuses on making what Benchee print out configurable to make it fit to your preferences :)

### Features (User Facing)
* The configuration now has a `:print` key where it is possible to configure in a map what Benchee prints out during benchmarking. All options are enabled by default (true). Options are:
  * `:benchmarking`  - print when Benchee starts benchmarking a new job (Benchmarking name ..)
  * `:configuration` - a summary of configured benchmarking options including estimated total run time is printed before benchmarking starts
  * `:fast_warning` - warnings are displayed if functions are executed too    fast leading to inaccurate measures
* There is also a new configuration option for the built-in console formatter. Which is also enabled by default:
  * `:comparison` - if the comparison of the different benchmarking jobs (x times slower than) is shown
* The pre-benchmarking output of the configuration now also prints the currently used Erlang and Elixir versions (similar to `elixir -v`)
* Add a space between the benchmarked time and the unit (microseconds)

## 0.3.0 (July 11, 2016)

This release switches internal data structures from lists of tuples to maps, allows the configuration of formatters, aggregates all values and hands them down so formatters can access the whole configuration, prints general configuration information and much more great stuff :)

### Breaking Changes (User Facing)
* The recommended data structure handed to `Benchee.run` was changed from a list of 2-element tuples to a map (`"Name" => benchmark_function`). However, **the old list of tuples still works but may be removed in future releases** (so it's not "breaking" _strictly_ speaking).
* You **can not have benchmark jobs with the same names anymore**, the last one wins here. This was the reason why previously the data structure was a list of tuples. However, having benchmarks with the same name is nonsensical as you can't discern their results in the output any way.

### Breaking Changes (Plugins)
* main data structure to hold benchmarks and results was changed from a list of 2-element tuples to a map (`"Name" => values`). That is for the jobs, the run times as well as the statistics. However, if you used something like `Enum.each(data, fn({name, value}) -> .. end)` you are still fine though, cause Elixir is awesome :)

### Features (User Facing)
* now takes a `parallel: number` configuration option and will then execute each job in parallel in as many parallel processes as specified in `number`. This way you can gather more samples in the same time and also simulate a system more under load. This is tricky, however. One of the use cases is also stress testing a system. Thanks @ldr
* the name column width is now determined based on the longest name. Thanks @alvinlindstam
* Print general configuration information at the start of the benchmark, including warmup, time, parallel and an estimated total run time
* New method `Benchee.Formatters.Console.output/1` that immediately prints to the console
* now takes a `formatters: [&My.Format.function/1, &Benchee.Formatters.console.output/1]` configuration option with which multiple formatters for the same benchmarking run can be configured when using `Benchee.run/2`. E.g. you can print results to the console and create a csv from that same run. Defaults to the builtin Console formatter.

### Features (Plugins)
* All previous configuration options are preserved after `Benchee.Statistics.statistics/1`, meaning there is access to raw run times as well as custom options etc. E.g. you could grab custom options like `%{csv: %{file: "my_file_name.csv"}}` to use.

### Bugfixes
* name columns are no longer truncated after 30 characters. Thanks @alvinlindstam

## 0.2.0 (June 11, 2016)

This release introduces warmup for benchmarks, nicer console output and the new `Benchee.measure` that runs the benchmarks previously defined instead of running them instantly.

### Breaking Changes (User Facing)
* `Benchee.benchmark/3` now doesn't run the benchmark anymore but simply adds it to `:jobs` in the config. The whole benchmark suite is then run via `Benchee.measure/1`. This only affects you if you used the more verbose way of defining benchmarks, `Benchee.run/2` still work as before.

### Breaking Changes (Plugins)
* the defined benchmarking are now preserved after running the benchmark under the `:jobs` key of the suite. Run times are added to the `:run_times` key of the suite (important for alternative statistics implementations)

### Features (User Facing)

* configuring a warmup time to run functions before measurements are taken can be configured via the `warmup` key in the config defaulting to 2 (seconds)

* statistics in console output are aligned right now for better comparisons
* last blank line of console output removed

### Features (Plugins)
* additionally supply the total standard deviation of iterations per second as `std_dev_ips` after `Benchee.Statistics.statistics`

### Bugfixes

* if no time/warmup is specified the function won't be called at all

## 0.1.0 (June 5, 2016)

Initial release
