defmodule Benchee.System do
  @moduledoc """
  Provides information about the system the benchmarks are run on.
  """

  alias Benchee.Suite

  @doc """
  Adds system information to the suite (currently elixir and erlang versions).
  """
  @spec system(Suite.t) :: Suite.t
  def system(suite = %Suite{}) do
    system_info = %{elixir: elixir(),
                    erlang: erlang(),
                    num_cores: num_cores(),
                    os: os(),
                    available_memory: available_memory(),
                    cpu_speed: cpu_speed()}
    %Suite{suite | system: system_info}
  end

  @doc """
  Returns current Elixir version in use.
  """
  def elixir, do: System.version()

  @doc """
  Returns the current erlang/otp version in use.
  """
  def erlang do
    otp_release = :erlang.system_info(:otp_release)
    file = Path.join([:code.root_dir, "releases", otp_release , "OTP_VERSION"])
    case File.read(file) do
      {:ok, version}    -> String.trim(version)
      {:error, reason}  ->
        IO.puts "Error trying to dermine erlang version #{reason}"
    end
  end

  @doc """
  Returns the number of cores available for the currently running VM.
  """
  def num_cores do
    System.schedulers_online()
  end

  @doc """
  Returns an atom representing the platform the VM is running on.
  """
  def os do
    {_, name} = :os.type()
    os(name)
  end
  defp os(:darwin), do: :macOS
  defp os(:nt), do: :Windows
  defp os(_), do: :Linux

  @doc """
  Returns a string with detailed information about the CPU the benchmarks are
  being performed on.
  """
  def cpu_speed, do: cpu_speed(os())

  defp cpu_speed(:Windows), do: "N/A"
  defp cpu_speed(:macOS), do: system_cmd("sysctl", ["-n", "machdep.cpu.brand_string"])
  defp cpu_speed(:Linux) do
    ["model name\t:" <> cpu_info] = linux_cmd("/proc/cpuinfo", ~r/model name.*:[\w \(\)\-\@\.]*ghz/i)
    String.trim(cpu_info)
  end

  @doc """
  Returns an integer with the total number of available memory on the machine
  running the benchmarks.
  """
  def available_memory, do: available_memory(os())

  defp available_memory(:Windows), do: "N/A"
  defp available_memory(:macOS) do
    {memory, _} = Integer.parse(system_cmd("sysctl", ["-n", "hw.memsize"]))
    format_memory(memory, 1_000_000_000)
  end
  defp available_memory(:Linux) do
    ["MemTotal:" <> memory] = linux_cmd("/proc/meminfo", ~r/MemTotal.*kB/)
    {memory, _} = memory
                  |> String.trim()
                  |> String.trim_trailing(" kB")
                  |> Integer.parse
    format_memory(memory, 1_000_000)
  end

  defp format_memory(memory, coefficient), do: "#{memory / coefficient} GB"

  defp linux_cmd(file, regex) do
    Regex.run(regex, system_cmd("cat", [file]))
  end

  defp system_cmd(cmd, args) do
    {output, exit_code} = System.cmd(cmd, args)
    if exit_code > 0 do
      IO.puts("Something went wrong trying to get system information:")
      IO.puts(output)
      "N/A"
    else
      output
    end
  end
end
