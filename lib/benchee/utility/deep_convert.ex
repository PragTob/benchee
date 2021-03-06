defmodule Benchee.Utility.DeepConvert do
  @moduledoc false

  @doc """
  Converts a deep keyword list to the corresponding deep map.

  ## Examples

  iex> Benchee.Utility.DeepConvert.to_map([a: 1, b: 2])
  %{a: 1, b: 2}

  iex> Benchee.Utility.DeepConvert.to_map([a: [b: 2], c: [d: 3, e: 4, e: 5]])
  %{a: %{b: 2}, c: %{d: 3, e: 5}}

  iex> Benchee.Utility.DeepConvert.to_map([a: [b: 2], c: [1, 2, 3], d: []])
  %{a: %{b: 2}, c: [1, 2, 3], d: []}

  iex> Benchee.Utility.DeepConvert.to_map(%{a: %{b: 2}, c: %{d: 3, e: 5}})
  %{a: %{b: 2}, c: %{d: 3, e: 5}}

  iex> Benchee.Utility.DeepConvert.to_map([])
  %{}

  iex> Benchee.Utility.DeepConvert.to_map([a: [b: [f: 5]]], [:a])
  %{a: [b: [f: 5]]}

  iex> Benchee.Utility.DeepConvert.to_map([a: [b: [f: 5]], c: [d: 3]], [:b])
  %{a: %{b: [f: 5]}, c: %{d: 3}}
  """
  def to_map(structure, exclusions \\ [])
  def to_map([], _exclusions), do: %{}
  def to_map(structure, exclusions), do: do_to_map(structure, exclusions)

  defp do_to_map(kwlist = [{_key, _value} | _tail], exclusions) do
    kwlist
    |> Enum.map(fn tuple -> to_map_element(tuple, exclusions) end)
    |> Map.new()
  end

  defp do_to_map(no_list, _exclusions), do: no_list

  defp to_map_element({key, value}, exclusions) do
    if Enum.member?(exclusions, key) do
      {key, value}
    else
      {key, do_to_map(value, exclusions)}
    end
  end
end
