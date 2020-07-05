defmodule Benchee.Test.FakeBenchmarkPrinter do
  @moduledoc false

  def duplicate_benchmark_warning(name) do
    send(self(), {:duplicate, name})
  end

  def system_information(_) do
    send(self(), :system_information)
  end

  def configuration_information(_) do
    send(self(), :configuration_information)
  end

  def benchmarking(name, input_information, _) do
    send(self(), {:benchmarking, name, input_information})
  end

  def fast_warning do
    send(self(), :fast_warning)
  end
end
