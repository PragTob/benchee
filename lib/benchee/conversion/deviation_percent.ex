defmodule Benchee.Conversion.DeviationPercent do
  @moduledoc """
  Helps with formatting for the standard deviation ratio converting it into the
  more common percent form.

  Only Benchee plugins should use this code.
  """

  alias Benchee.Conversion.Format

  @behaviour Format

  @doc """
  Formates the standard deviation ratio to an equivalent percent number
  including special signs. The ± is an important part of it as it shows that
  the deviation might be up but also might be down.

  ## Examples

      iex> Benchee.Conversion.DeviationPercent.format(0.12345)
      "±12.35%"

      iex> Benchee.Conversion.DeviationPercent.format(1)
      "±100.00%"
  """
  def format(std_dev_ratio) do
    "~ts~.2f%"
    |> :io_lib.format(["±", std_dev_ratio * 100.0])
    |> to_string
  end
end
