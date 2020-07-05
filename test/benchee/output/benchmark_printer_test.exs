defmodule Benchee.Output.BenchmarkPrintertest do
  use ExUnit.Case, async: true

  alias Benchee.{Benchmark, Configuration, Scenario}

  import ExUnit.CaptureIO
  import Benchee.Output.BenchmarkPrinter

  @system_info %{
    elixir: "1.4",
    erlang: "19.2",
    os: :macOS,
    num_cores: 4,
    cpu_speed: "Intel(R) Core(TM) i5-4260U CPU @ 1.40GHz",
    available_memory: 8_568_392_814
  }

  test ".duplicate_benchmark_warning" do
    output =
      capture_io(fn ->
        duplicate_benchmark_warning("Something")
      end)

    assert output =~ "same name"
    assert output =~ "Something"
  end

  describe ".system_information" do
    output =
      capture_io(fn ->
        %{
          configuration: %Configuration{
            parallel: 2,
            time: 10_000,
            warmup: 0,
            inputs: nil
          },
          # scenarios: [%Scenario{job_name: "one"}, %Scenario{job_name: "two"}],
          system: @system_info
        }
        |> system_information
      end)

    assert output =~ "Erlang 19.2"
    assert output =~ "Elixir 1.4"
    assert output =~ "Intel"
    assert output =~ "Cores: 4"
    assert output =~ "macOS"
    assert output =~ "8568392814"
  end

  describe ".configuration_information" do
    test "sys information" do
      output =
        capture_io(fn ->
          %{
            configuration: %Configuration{parallel: 2, time: 10_000, warmup: 0, inputs: nil},
            scenarios: [%Scenario{job_name: "one"}, %Scenario{job_name: "two"}],
            system: @system_info
          }
          |> configuration_information
        end)

      assert output =~ ~r/following configuration/i
      assert output =~ "warmup: 0 ns"
      assert output =~ "time: 10 μs"
      assert output =~ "memory time: 0 ns"
      assert output =~ "parallel: 2"
      assert output =~ "Estimated total run time: 20 μs"
    end

    test "it scales times appropriately" do
      output =
        capture_io(fn ->
          %{
            configuration: %Configuration{
              parallel: 1,
              time: 60_000_000_000,
              warmup: 10_000_000_000,
              memory_time: 5_000_000_000,
              inputs: nil
            },
            scenarios: [%Scenario{job_name: "one"}, %Scenario{job_name: "two"}],
            system: @system_info
          }
          |> configuration_information
        end)

      assert output =~ "warmup: 10 s"
      assert output =~ "time: 1 min"
      assert output =~ "memory time: 5 s"
      assert output =~ "parallel: 1"
      assert output =~ "Estimated total run time: 2.50 min"
    end

    @inputs %{"Arg 1" => 1, "Arg 2" => 2}
    test "multiple inputs" do
      output =
        capture_io(fn ->
          %{
            configuration: %{
              parallel: 2,
              time: 10_000,
              warmup: 0,
              memory_time: 1_000,
              reduction_time: 0,
              inputs: @inputs
            },
            scenarios: [
              %Scenario{job_name: "one", input_name: "Arg 1", input: 1},
              %Scenario{job_name: "one", input_name: "Arg 2", input: 2},
              %Scenario{job_name: "two", input_name: "Arg 1", input: 1},
              %Scenario{job_name: "two", input_name: "Arg 2", input: 2}
            ],
            system: @system_info
          }
          |> configuration_information
        end)

      assert output =~ "time: 10 μs"
      assert output =~ "memory time: 1 μs"
      assert output =~ "reduction time: 0 ns"
      assert output =~ "parallel: 2"
      assert output =~ "inputs: Arg 1, Arg 2"
      assert output =~ "Estimated total run time: 44 μs"
    end

    test "does not print if disabled" do
      output =
        capture_io(fn ->
          %{configuration: %{print: %{configuration: false}}}
          |> configuration_information
        end)

      assert output == ""

      output =
        capture_io(fn ->
          %{configuration: %{print: %{system: false}}}
          |> system_information
        end)

      assert output == ""
    end
  end

  describe ".benchmarking" do
    @no_input Benchmark.no_input()
    test "prints information that it's currently benchmarking without input" do
      output =
        capture_io(fn ->
          benchmarking("Something", @no_input, %{})
        end)

      assert output =~ ~r/Benchmarking.+Something/i
    end

    test "prints information that it's currently benchmarking with input" do
      output =
        capture_io(fn ->
          benchmarking("Something", "great input", %{})
        end)

      assert output =~ ~r/Benchmarking.+Something with input great input/i
    end

    test "doesn't print if it's deactivated" do
      output =
        capture_io(fn ->
          benchmarking("A", "some", %{print: %{benchmarking: false}})
        end)

      assert output == ""
    end

    test "doesn't print if all times are set to 0" do
      output =
        capture_io(fn ->
          benchmarking("Never", "don't care", %Configuration{
            time: 0.0,
            warmup: 0.0,
            memory_time: 0.0
          })
        end)

      assert output == ""
    end
  end

  test ".fast_warning warns with reference to more information" do
    output =
      capture_io(fn ->
        fast_warning()
      end)

    assert output =~ ~r/fast/i
    assert output =~ ~r/unreliable/i
    assert output =~ "benchee/wiki"
  end
end
