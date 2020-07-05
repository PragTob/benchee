defmodule Benchee.BenchmarkTest do
  use ExUnit.Case, async: true

  alias Benchee.{
    Benchmark,
    Configuration,
    Scenario,
    Suite
  }

  alias Benchee.Benchmark.ScenarioContext
  alias Benchee.Test.FakeBenchmarkPrinter, as: TestPrinter
  alias Benchee.Test.FakeBenchmarkRunner, as: TestRunner

  describe ".benchmark" do
    test "can add jobs with atom keys but converts them to string" do
      suite =
        %Suite{}
        |> Benchmark.benchmark("one job", fn -> 1 end)
        |> Benchmark.benchmark(:something, fn -> 2 end)

      job_names = Enum.map(suite.scenarios, fn scenario -> scenario.job_name end)
      assert job_names == ["one job", "something"]
      names = Enum.map(suite.scenarios, fn scenario -> scenario.job_name end)
      assert names == ["one job", "something"]
    end

    test "warns when adding the same job again even if it's atom and string" do
      one_fun = fn -> 1 end
      scenario = %Scenario{job_name: "one", function: one_fun, name: "one"}
      suite = %Suite{scenarios: [scenario]}
      new_suite = Benchmark.benchmark(suite, :one, fn -> 42 end, TestPrinter)

      assert new_suite == %Suite{scenarios: [scenario]}

      assert_receive {:duplicate, "one"}
    end

    test "adds a %Scenario{} to the suite for a job with no inputs" do
      job_name = "one job"
      function = fn -> 1 end
      config = %Configuration{inputs: nil}
      suite = Benchmark.benchmark(%Suite{configuration: config}, job_name, function)

      expected_scenario = %Scenario{
        name: job_name,
        job_name: job_name,
        function: function,
        input: Benchmark.no_input(),
        input_name: Benchmark.no_input()
      }

      assert suite.scenarios == [expected_scenario]
    end

    test "adds a %Scenario{} to the suite for each input of a job" do
      config = %Configuration{inputs: %{"large" => 100_000, "small" => 10}}
      suite = Benchmark.benchmark(%Suite{configuration: config}, "one_job", fn -> 1 end)
      input_names = Enum.map(suite.scenarios, fn scenario -> scenario.input_name end)
      inputs = Enum.map(suite.scenarios, fn scenario -> scenario.input end)

      assert length(suite.scenarios) == 2
      assert input_names == ["large", "small"]
      assert inputs == [100_000, 10]
    end

    test "can deal with the options tuple" do
      function = fn -> 1 end
      before = fn -> 2 end
      after_scenario = fn -> 3 end

      suite =
        %Suite{}
        |> Benchmark.benchmark(
          "job",
          {function, before_each: before, after_scenario: after_scenario}
        )

      [scenario] = suite.scenarios

      assert %{
               job_name: "job",
               function: ^function,
               before_each: ^before,
               after_scenario: ^after_scenario
             } = scenario
    end

    test "doesn't treat tagged scenarios as duplicates" do
      suite = %Suite{scenarios: [%Scenario{job_name: "job", tag: "what"}]}
      new_suite = Benchmark.benchmark(suite, "job", fn -> 1 end)

      assert length(new_suite.scenarios) == 2
    end
  end

  describe "collect/3" do
    test "prints the configuration information" do
      Benchmark.collect(%Suite{}, TestPrinter, TestRunner)

      assert_receive :system_information
      assert_receive :configuration_information
    end

    test "sends the correct data to the benchmark runner" do
      scenarios = [%Scenario{job_name: "job_one"}]
      config = %Configuration{}
      suite = %Suite{scenarios: scenarios, configuration: config}
      scenario_context = %ScenarioContext{config: config, printer: TestPrinter}

      Benchmark.collect(suite, TestPrinter, TestRunner)

      assert_receive {:run_scenarios, ^scenarios, ^scenario_context}
    end

    test "returns a suite with scenarios returned from the runner" do
      scenarios = [%Scenario{job_name: "one", function: fn -> 1 end}]
      suite = %Suite{scenarios: scenarios}

      run_times =
        suite
        |> Benchmark.collect(TestPrinter, TestRunner)
        |> (fn suite -> suite.scenarios end).()
        |> Enum.map(fn scenario -> scenario.run_time_data.samples end)

      assert length(run_times) == 1
      refute Enum.any?(run_times, fn run_time -> Enum.empty?(run_time) end)
    end
  end
end
