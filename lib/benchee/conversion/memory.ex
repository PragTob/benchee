defmodule Benchee.Conversion.Memory do
  @moduledoc """
  Unit scaling for memory converting from bytes to kilobytes and others.

  Only Benchee plugins should use this code.
  """

  alias Benchee.Conversion.{Format, Scale, Unit}

  @behaviour Scale
  @behaviour Format

  @bytes_per_kilobyte 1024
  @bytes_per_megabyte @bytes_per_kilobyte * @bytes_per_kilobyte
  @bytes_per_gigabyte @bytes_per_megabyte * @bytes_per_kilobyte
  @bytes_per_terabyte @bytes_per_gigabyte * @bytes_per_kilobyte

  @units %{
    terabyte: %Unit{
      name: :terabyte,
      magnitude: @bytes_per_terabyte,
      label: "TB",
      long: "Terabytes"
    },
    gigabyte: %Unit{
      name: :gigabyte,
      magnitude: @bytes_per_gigabyte,
      label: "GB",
      long: "Gigabytes"
    },
    megabyte: %Unit{
      name: :megabyte,
      magnitude: @bytes_per_megabyte,
      label: "MB",
      long: "Megabytes"
    },
    kilobyte: %Unit{
      name: :kilobyte,
      magnitude: @bytes_per_kilobyte,
      label: "KB",
      long: "Kilobytes"
    },
    byte: %Unit{
      name: :byte,
      magnitude: 1,
      label: "B",
      long: "Bytes"
    }
  }

  @type unit_atom :: :byte | :kilobyte | :megabyte | :gigabyte | :terabyte
  @type any_unit :: unit_atom | Unit.t()

  @doc """
  Converts a value for a specified %Unit or unit atom and converts it to the equivalent of another unit of measure.

  ## Examples

    iex> {value, unit} = Benchee.Conversion.Memory.convert({1024, :kilobyte}, :megabyte)
    iex> value
    1.0
    iex> unit.name
    :megabyte

    iex> current_unit = Benchee.Conversion.Memory.unit_for :kilobyte
    iex> {value, unit} = Benchee.Conversion.Memory.convert({1024, current_unit}, :megabyte)
    iex> value
    1.0
    iex> unit.name
    :megabyte
  """
  @spec convert({number, any_unit}, any_unit) :: Scale.scaled_number()
  def convert(number_and_unit, desired_unit) do
    Scale.convert(number_and_unit, desired_unit, __MODULE__)
  end

  # Scaling functions

  @doc """
  Scales a memory value in bytes into a larger unit if appropriate

  ## Examples

    iex> {value, unit} = Benchee.Conversion.Memory.scale(1)
    iex> value
    1.0
    iex> unit.name
    :byte

    iex> {value, unit} = Benchee.Conversion.Memory.scale(1_234)
    iex> value
    1.205078125
    iex> unit.name
    :kilobyte

    iex> {value, unit} = Benchee.Conversion.Memory.scale(11_234_567_890.123)
    iex> value
    10.463006692121736
    iex> unit.name
    :gigabyte

    iex> {value, unit} = Benchee.Conversion.Memory.scale(1_111_234_567_890.123)
    iex> value
    1.0106619519229962
    iex> unit.name
    :terabyte
  """
  def scale(memory) when memory >= @bytes_per_terabyte do
    scale_with_unit(memory, :terabyte)
  end

  def scale(memory) when memory >= @bytes_per_gigabyte do
    scale_with_unit(memory, :gigabyte)
  end

  def scale(memory) when memory >= @bytes_per_megabyte do
    scale_with_unit(memory, :megabyte)
  end

  def scale(memory) when memory >= @bytes_per_kilobyte do
    scale_with_unit(memory, :kilobyte)
  end

  def scale(memory) do
    scale_with_unit(memory, :byte)
  end

  # Helper function for returning a tuple of {value, unit}
  defp scale_with_unit(nil, _) do
    {nil, nil}
  end

  defp scale_with_unit(memory, unit) do
    {scale(memory, unit), unit_for(unit)}
  end

  @doc """
  Get a unit by its atom representation. If handed already a %Unit{} struct it
  just returns it.

  ## Examples

      iex> Benchee.Conversion.Memory.unit_for :gigabyte
      %Benchee.Conversion.Unit{
          name:      :gigabyte,
          magnitude: 1_073_741_824,
          label:     "GB",
          long:      "Gigabytes"
      }

      iex> Benchee.Conversion.Memory.unit_for(%Benchee.Conversion.Unit{
      ...>   name:      :gigabyte,
      ...>   magnitude: 1_073_741_824,
      ...>   label:     "GB",
      ...>   long:      "Gigabytes"
      ...>})
      %Benchee.Conversion.Unit{
          name:      :gigabyte,
          magnitude: 1_073_741_824,
          label:     "GB",
          long:      "Gigabytes"
      }
  """
  def unit_for(unit) do
    Scale.unit_for(@units, unit)
  end

  @doc """
  Scales a memory value in bytes into a value in the specified unit

  ## Examples

      iex> Benchee.Conversion.Memory.scale(12345, :kilobyte)
      12.0556640625

      iex> Benchee.Conversion.Memory.scale(12345, :megabyte)
      0.011773109436035156

      iex> Benchee.Conversion.Memory.scale(123_456_789, :gigabyte)
      0.11497809458523989

  """
  def scale(count, unit) do
    Scale.scale(count, unit, __MODULE__)
  end

  @doc """
  Finds the best unit for a list of memory units. By default, chooses the most common
  unit. In case of tie, chooses the largest of the most common units.

  Pass `[strategy: :smallest]` to always return the smallest unit in the list.
  Pass `[strategy: :largest]` to always return the largest unit in the list.
  Pass `[strategy: :best]` to always return the most frequent unit in the list.
  Pass `[strategy: :none]` to always return :byte.

  ## Examples

      iex> Benchee.Conversion.Memory.best([23, 23_000, 34_000, 2_340_000]).name
      :kilobyte

      iex> Benchee.Conversion.Memory.best([23, 23_000, 34_000, 2_340_000, 3_450_000]).name
      :megabyte

      iex> Benchee.Conversion.Memory.best([23, 23_000, 34_000, 2_340_000], strategy: :smallest).name
      :byte

      iex> Benchee.Conversion.Memory.best([23, 23_000, 34_000, 2_340_000], strategy: :largest).name
      :megabyte
  """
  def best(list, opts \\ [strategy: :best])

  def best(list, opts) do
    Scale.best_unit(list, __MODULE__, opts)
  end

  @doc """
  The most basic unit in which memory occur, byte.

  ## Examples

      iex> Benchee.Conversion.Memory.base_unit.name
      :byte

  """
  def base_unit, do: unit_for(:byte)

  @doc """
  Formats a number as a string, with a unit label. To specify the unit, pass
  a tuple of `{value, unit_atom}` like `{1_234, :kilobyte}`

  ## Examples

      iex> Benchee.Conversion.Memory.format(45_678.9)
      "44.61 KB"

      iex> Benchee.Conversion.Memory.format(45.6789)
      "45.68 B"

      iex> Benchee.Conversion.Memory.format({45.6789, :kilobyte})
      "45.68 KB"

      iex> Benchee.Conversion.Memory.format {45.6789,
      ...>   %Benchee.Conversion.Unit{
      ...>     long: "Kilobytes", magnitude: 1024, label: "KB"}
      ...>   }
      "45.68 KB"

  """
  def format(memory) do
    Format.format(memory, __MODULE__)
  end
end
