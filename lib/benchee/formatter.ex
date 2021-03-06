defmodule Benchee.Formatter do
  @moduledoc """
  Defines a behaviour for formatters in Benchee, and functions to work with these.

  When implementing a Benchee formatter as a behaviour please adopt this
  behaviour, as it helps with uniformity and also allows at least the `.format`
  function of formatters to be run in parallel.

  The module itself then has functions to deal with formatters defined in this way
  allowing for parallel output through `output/1` or just output a single formatter
  through `output/3`.
  """

  alias Benchee.{Suite, Utility.Parallel}
  alias Benchee.Utility.DeepConvert

  @typedoc """
  Options given to formatters, entirely defined by formatter authors.
  """
  @type options :: any

  @doc """
  Takes the suite and returns whatever representation the formatter wants to use
  to output that information. It is important that this function **needs to be
  pure** (aka have no side effects) as Benchee will run `format/1` functions
  of multiple formatters in parallel. The result will then be passed to
  `write/1`.
  """
  @callback format(Suite.t(), options) :: any

  @doc """
  Takes the return value of `format/1` and then performs some I/O for the user
  to actually see the formatted data (UI, File IO, HTTP, ...)
  """
  @callback write(any, options) :: :ok | {:error, String.t()}

  @doc """
  Format and output all configured formatters and formatting functions.

  Expects a suite that already has been run through all previous functions so has the aggregated
  statistics etc. that the formatters rely on.

  Works by invoking the `format/2` and `write/2` functions defined in this module. The `format/2`
  functions are actually called in parallel (as they should be pure) - due to potential
  interference the `write/2` functions are called serial.

  Also handles pure functions that will then be called with the suite.

  You can't rely on the formatters being called in pre determined order.
  """
  @spec output(Suite.t()) :: Suite.t()
  def output(suite = %{configuration: %{formatters: formatters}}) do
    {parallelizable, serial} =
      formatters
      |> Enum.map(&normalize_module_configuration/1)
      |> Enum.split_with(&is_tuple/1)

    # why do we ignore this suite? It shouldn't be changed anyway.
    # We assign it because dialyzer would complain otherwise :D
    _suite = parallel_output(suite, parallelizable)

    Enum.each(serial, fn function -> function.(suite) end)

    suite
  end

  defp normalize_module_configuration(formatter) when is_function(formatter, 1), do: formatter

  defp normalize_module_configuration({module, opts}) do
    normalize_module_configuration(module, DeepConvert.to_map(opts))
  end

  defp normalize_module_configuration(module) when is_atom(module) do
    normalize_module_configuration(module, %{})
  end

  defp normalize_module_configuration(module, opts) do
    if formatter_module?(module) do
      {module, opts}
    else
      raise_behaviour_not_implemented(module)
    end
  end

  defp formatter_module?(module) do
    :attributes
    |> module.module_info()
    |> Keyword.get(:behaviour, [])
    |> Enum.member?(Benchee.Formatter)
  end

  @spec raise_behaviour_not_implemented(atom) :: no_return()
  defp raise_behaviour_not_implemented(module) do
    raise """
    The module you're attempting to use as a formatter - #{module} - does
    not implement the `Benchee.Formatter` behaviour.
    """
  end

  @doc """
  Output a suite with a given formatter and options.

  Replacement for the old `MyFormatter.output/1` - calls `format/2` and `write/2` one after another
  to create the output defined by the given formatter module. For the given options please refer
  to the documentation of the formatters you use.
  """
  @spec output(Suite.t(), module, options) :: Suite.t()
  def output(suite, formatter, options \\ %{}) do
    :ok =
      suite
      |> formatter.format(options)
      |> formatter.write(options)

    suite
  end

  # Invokes `format/2` and `write/2` as defined by the `Benchee.Formatter`
  # behaviour. The output for all formatters is generated in parallel, and then
  # the results of that formatting are written in sequence.
  defp parallel_output(suite, module_configurations) do
    module_configurations
    |> Parallel.map(fn {module, options} -> {module, options, module.format(suite, options)} end)
    |> Enum.each(fn {module, options, output} -> module.write(output, options) end)

    suite
  end
end
