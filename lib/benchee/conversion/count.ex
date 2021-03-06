defmodule Benchee.Conversion.Count do
  @moduledoc """
  Unit scaling for counts, such that 1000000 can be converted to 1 Million.

  Only Benchee plugins should use this code.
  """

  alias Benchee.Conversion.{Format, Scale, Unit}

  @behaviour Scale
  @behaviour Format

  @one_billion 1_000_000_000
  @one_million 1_000_000
  @one_thousand 1_000

  @units %{
    billion: %Unit{
      name: :billion,
      magnitude: @one_billion,
      label: "B",
      long: "Billion"
    },
    million: %Unit{
      name: :million,
      magnitude: @one_million,
      label: "M",
      long: "Million"
    },
    thousand: %Unit{
      name: :thousand,
      magnitude: @one_thousand,
      label: "K",
      long: "Thousand"
    },
    one: %Unit{
      name: :one,
      magnitude: 1,
      label: "",
      long: ""
    }
  }

  @type unit_atoms :: :one | :thousand | :million | :billion
  @type units :: unit_atoms | Unit.t()

  @doc """
  Scales a value representing a count in ones into a larger unit if appropriate

  ## Examples

      iex> {value, unit} = Benchee.Conversion.Count.scale(4_321.09)
      iex> value
      4.32109
      iex> unit.name
      :thousand

      iex> {value, unit} = Benchee.Conversion.Count.scale(0.0045)
      iex> value
      0.0045
      iex> unit.name
      :one

  """
  def scale(count) when count >= @one_billion do
    scale_with_unit(count, :billion)
  end

  def scale(count) when count >= @one_million do
    scale_with_unit(count, :million)
  end

  def scale(count) when count >= @one_thousand do
    scale_with_unit(count, :thousand)
  end

  def scale(count) do
    scale_with_unit(count, :one)
  end

  # Helper function for returning a tuple of {value, unit}
  defp scale_with_unit(count, unit) do
    {scale(count, unit), unit_for(unit)}
  end

  @doc """
  Get a unit by its atom representation. If handed already a %Unit{} struct it
  just returns it.

  ## Examples

      iex> Benchee.Conversion.Count.unit_for :thousand
      %Benchee.Conversion.Unit{
        name:      :thousand,
        magnitude: 1_000,
        label:     "K",
        long:      "Thousand"
      }

      iex> Benchee.Conversion.Count.unit_for(%Benchee.Conversion.Unit{
      ...>   name:      :thousand,
      ...>   magnitude: 1_000,
      ...>   label:     "K",
      ...>   long:      "Thousand"
      ...>})
      %Benchee.Conversion.Unit{
        name:      :thousand,
        magnitude: 1_000,
        label:     "K",
        long:      "Thousand"
      }
  """
  def unit_for(unit) do
    Scale.unit_for(@units, unit)
  end

  @doc """
  Scales a value representing a count in ones into a specified unit

  ## Examples

      iex> Benchee.Conversion.Count.scale(12345, :one)
      12345.0

      iex> Benchee.Conversion.Count.scale(12345, :thousand)
      12.345

      iex> Benchee.Conversion.Count.scale(12345, :billion)
      1.2345e-5

      iex> Benchee.Conversion.Count.scale(12345, :million)
      0.012345

  """
  def scale(count, unit) do
    Scale.scale(count, unit, __MODULE__)
  end

  @doc """
  Converts a value for a specified %Unit or unit atom and converts it to the equivalent of another unit of measure.

  ## Examples

    iex> {value, unit} = Benchee.Conversion.Count.convert({2500, :thousand}, :million)
    iex> value
    2.5
    iex> unit.name
    :million
  """
  def convert(number_and_unit, desired_unit) do
    Scale.convert(number_and_unit, desired_unit, __MODULE__)
  end

  @doc """
  Finds the best unit for a list of counts. By default, chooses the most common
  unit. In case of tie, chooses the largest of the most common units.

  Pass `[strategy: :smallest]` to always return the smallest unit in the list.
  Pass `[strategy: :largest]` to always return the largest unit in the list.

  ## Examples

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000]).name
      :thousand

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000, 3_450_000]).name
      :million

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000], strategy: :smallest).name
      :one

      iex> Benchee.Conversion.Count.best([23, 23_000, 34_000, 2_340_000], strategy: :largest).name
      :million

  """
  def best(list, opts \\ [strategy: :best])

  def best(list, opts) do
    Scale.best_unit(list, __MODULE__, opts)
  end

  @doc """
  The raw count, unscaled.

  ## Examples

      iex> Benchee.Conversion.Count.base_unit.name
      :one

  """
  def base_unit, do: unit_for(:one)

  @doc """
  Formats a number as a string, with a unit label. To specify the unit, pass
  a tuple of `{value, unit_atom}` like `{1_234, :million}`

  ## Examples

      iex> Benchee.Conversion.Count.format(45_678.9)
      "45.68 K"

      iex> Benchee.Conversion.Count.format(45.6789)
      "45.68"

      iex> Benchee.Conversion.Count.format({45.6789, :thousand})
      "45.68 K"

      iex> Benchee.Conversion.Count.format({45.6789, %Benchee.Conversion.Unit{long: "Thousand", magnitude: "1_000", label: "K"}})
      "45.68 K"
  """
  def format(count) do
    Format.format(count, __MODULE__)
  end
end
