defmodule Benchee.SystemTest do
  use ExUnit.Case, async: true

  alias Benchee.Suite
  import ExUnit.CaptureIO

  test ".system adds the content to a given suite" do
    system_info = Benchee.System.system(%Suite{})
    assert %{system: %{elixir: _, erlang: _, num_cores: _, os: _,
                       cpu_speed: _, available_memory: _}} = system_info
  end

  test ".elixir returns the current elixir version" do
    assert Benchee.System.elixir() =~ ~r/\d+\.\d+\.\d+/
  end

  test ".erlang returns the current erlang version in use" do
    version = Benchee.System.erlang()
    assert version =~ to_string(:erlang.system_info(:otp_release))
    assert version =~ ~r/\d+\.\d+/
    refute version =~ "\n"
  end

  test ".num_cores returns the number of cores on the running VM" do
    assert Benchee.System.num_cores() > 0
  end

  test ".os returns an atom of the current os" do
    assert Enum.member?([:Linux, :macOS, :Windows], Benchee.System.os())
  end

  test ".cpu_speed returns the speed of the current cpu" do
    assert Benchee.System.cpu_speed() =~ ~r/\d+.*hz/i
  end

  test ".available_memory returns the available memory on the computer" do
    {num, rest} = Float.parse(Benchee.System.available_memory())
    assert num > 0
    assert rest =~ ~r/GB/
  end

  test ".system_cmd handles errors gracefully" do
    system_func = fn(_, _) -> {"ERROR", 1} end
    success_callback = fn(_) -> nil end
    captured_io = capture_io(fn ->
      Benchee.System.system_cmd("cat", "dev/null", success_callback, system_func)
    end)

    assert captured_io =~ "Something went wrong"
    assert captured_io =~ "ERROR"
    capture_io fn ->
      assert Benchee.System.system_cmd("cat", "dev/null", success_callback, system_func) == "N/A"
    end
  end

  test ".parse_cpu_for handles Semaphore specific CI results" do
    semaphore_output = "model name	: Intel Core Processor (Haswell)"
    system_func = fn(_, _) -> {semaphore_output, 0} end
    success_callback = fn(output) -> Benchee.System.parse_cpu_for(:Linux, output) end

    output = Benchee.System.system_cmd("test", "args", success_callback, system_func)
    assert output =~ "Haswell"
  end

  test ".parse_cpu_for handles unknown formats on Linux" do
    unknown_processor = "Bender D Bending Rodriguez"
    system_func = fn(_, _) -> {unknown_processor, 0} end
    success_callback = fn(output) -> Benchee.System.parse_cpu_for(:Linux, output) end

    output = Benchee.System.system_cmd("test", "args", success_callback, system_func)
    assert output =~ "Unrecognized processor"
  end
end
