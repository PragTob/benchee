defmodule Benchee.Conversion.Duration do
  @moduledoc """
  Unit scaling for duration converting from microseconds to minutes and others.

  Only Benchee plugins should use this code.
  """

  alias Benchee.Conversion.{Format, Scale, Unit}

  @behaviour Scale
  @behaviour Format

  @nanoseconds_per_microsecond 1000
  @microseconds_per_millisecond 1000
  @milliseconds_per_second 1000
  @seconds_per_minute 60
  @minutes_per_hour 60

  @nanoseconds_per_millisecond @nanoseconds_per_microsecond * @microseconds_per_millisecond
  @nanoseconds_per_second @nanoseconds_per_millisecond * @milliseconds_per_second
  @nanoseconds_per_minute @nanoseconds_per_second * @seconds_per_minute
  @nanoseconds_per_hour @nanoseconds_per_minute * @minutes_per_hour

  @units %{
    hour: %Unit{
      name: :hour,
      magnitude: @nanoseconds_per_hour,
      label: "h",
      long: "Hours"
    },
    minute: %Unit{
      name: :minute,
      magnitude: @nanoseconds_per_minute,
      label: "min",
      long: "Minutes"
    },
    second: %Unit{
      name: :second,
      magnitude: @nanoseconds_per_second,
      label: "s",
      long: "Seconds"
    },
    millisecond: %Unit{
      name: :millisecond,
      magnitude: @nanoseconds_per_millisecond,
      label: "ms",
      long: "Milliseconds"
    },
    microsecond: %Unit{
      name: :microsecond,
      magnitude: @nanoseconds_per_microsecond,
      label: "μs",
      long: "Microseconds"
    },
    nanosecond: %Unit{
      name: :nanosecond,
      magnitude: 1,
      label: "ns",
      long: "Nanoseconds"
    }
  }

  @doc """
  Scales a duration value in nanoseconds into a larger unit if appropriate

  ## Examples

      iex> {value, unit} = Benchee.Conversion.Duration.scale(1)
      iex> value
      1.0
      iex> unit.name
      :nanosecond

      iex> {value, unit} = Benchee.Conversion.Duration.scale(1_234)
      iex> value
      1.234
      iex> unit.name
      :microsecond

      iex> {value, unit} = Benchee.Conversion.Duration.scale(11_234_567_890_123)
      iex> value
      3.1207133028119443
      iex> unit.name
      :hour
  """
  def scale(duration) when duration >= @nanoseconds_per_hour do
    scale_with_unit(duration, :hour)
  end

  def scale(duration) when duration >= @nanoseconds_per_minute do
    scale_with_unit(duration, :minute)
  end

  def scale(duration) when duration >= @nanoseconds_per_second do
    scale_with_unit(duration, :second)
  end

  def scale(duration) when duration >= @nanoseconds_per_millisecond do
    scale_with_unit(duration, :millisecond)
  end

  def scale(duration) when duration >= @nanoseconds_per_microsecond do
    scale_with_unit(duration, :microsecond)
  end

  def scale(duration) do
    scale_with_unit(duration, :nanosecond)
  end

  # Helper function for returning a tuple of {value, unit}
  defp scale_with_unit(duration, unit) do
    {scale(duration, unit), unit_for(unit)}
  end

  @doc """
  Get a unit by its atom representation. If handed already a %Unit{} struct it
  just returns it.

  ## Examples

      iex> Benchee.Conversion.Duration.unit_for :hour
      %Benchee.Conversion.Unit{
        name:      :hour,
        magnitude: 3_600_000_000_000,
        label:     "h",
        long:      "Hours"
      }

      iex> Benchee.Conversion.Duration.unit_for(%Benchee.Conversion.Unit{
      ...>   name:      :hour,
      ...>   magnitude: 3_600_000_000_000,
      ...>   label:     "h",
      ...>   long:      "Hours"
      ...>})
      %Benchee.Conversion.Unit{
        name:      :hour,
        magnitude: 3_600_000_000_000,
        label:     "h",
        long:      "Hours"
      }
  """
  def unit_for(unit) do
    Scale.unit_for(@units, unit)
  end

  @doc """
  Scales a duration value in nanoseconds into a value in the specified unit

  ## Examples

      iex> Benchee.Conversion.Duration.scale(12345, :nanosecond)
      12345.0

      iex> Benchee.Conversion.Duration.scale(12345, :microsecond)
      12.345

      iex> Benchee.Conversion.Duration.scale(12345, :minute)
      2.0575e-7

  """
  def scale(count, unit) do
    Scale.scale(count, unit, __MODULE__)
  end

  @doc """
  Converts a value for a specified %Unit or unit atom and converts it to the equivalent of another unit of measure.

  ## Examples

    iex> {value, unit} = Benchee.Conversion.Duration.convert({90, :minute}, :hour)
    iex> value
    1.5
    iex> unit.name
    :hour
  """
  def convert(number_and_unit, desired_unit) do
    Scale.convert(number_and_unit, desired_unit, __MODULE__)
  end

  @doc """
  Converts a value of the given unit into the desired unit, returning only the value not the unit.

  ## Examples

      iex> Benchee.Conversion.Duration.convert_value({1.234, :second}, :microsecond)
      1_234_000.0

      iex> Benchee.Conversion.Duration.convert_value({1.234, :minute}, :microsecond)
      7.404e7

      iex> microseconds = Benchee.Conversion.Duration.convert_value({1.234, :minute}, :microsecond)
      iex> {value, _} = Benchee.Conversion.Duration.convert({microseconds, :microsecond}, :minute)
      iex> value
      1.234

  """
  def convert_value({duration, unit}, desired_unit) do
    {value, _} = convert({duration, unit}, desired_unit)
    value
  end

  @doc """
  Finds the best unit for a list of durations. By default, chooses the most common
  unit. In case of tie, chooses the largest of the most common units.

  Pass `[strategy: :smallest]` to always return the smallest unit in the list.
  Pass `[strategy: :largest]` to always return the largest unit in the list.

  ## Examples

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000]).name
      :microsecond

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000_000, 2_340_000_000, 3_450_000_000]).name
      :second

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000], strategy: :smallest).name
      :nanosecond

      iex> Benchee.Conversion.Duration.best([23, 23_000, 34_000, 2_340_000_000], strategy: :largest).name
      :second
  """
  def best(list, opts \\ [strategy: :best])

  def best(list, opts) do
    Scale.best_unit(list, __MODULE__, opts)
  end

  @doc """
  The most basic unit in which measurements occur.

  ## Examples

      iex> Benchee.Conversion.Duration.base_unit.name
      :nanosecond

  """
  def base_unit, do: unit_for(:nanosecond)

  @doc """
  Formats a number as a string, with a unit label. To specify the unit, pass
  a tuple of `{value, unit_atom}` like `{1_234, :second}`

  ## Examples

      iex> Benchee.Conversion.Duration.format(45_678.9)
      "45.68 μs"

      iex> Benchee.Conversion.Duration.format(45.6789)
      "45.68 ns"

      iex> Benchee.Conversion.Duration.format({45.6789, :millisecond})
      "45.68 ms"

      iex> Benchee.Conversion.Duration.format {45.6789,
      ...>   %Benchee.Conversion.Unit{
      ...>     long: "Milliseconds", magnitude: 1000, label: "ms"}
      ...>   }
      "45.68 ms"

  """
  def format(duration) do
    Format.format(duration, __MODULE__)
  end
end
