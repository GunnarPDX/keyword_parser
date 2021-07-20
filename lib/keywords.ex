defmodule Keywords do
  @moduledoc """
  Documentation for `KeywordParser`.
  """

  alias Keywords.Pattern

  @doc """
  Parses tickers from string

  ## Examples
      KeywordParser.scan(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stock_tickers)
      [XOM, AAPL, TSLA, PLTR, AMZN]
  """
  def scan(nil, _, _), do: []
  def scan(string, pattern, opts \\ []) do
    pattern = Pattern.get(pattern)
    bit_matches = :binary.matches(string, pattern)
    bit_matches = for x <- bit_matches, do: :binary.part(string, x)
    Enum.uniq(bit_matches)
  end

  @doc """
  Recompiles keyword pattern.
  """
  def recompile(pid, keyword_list), do: Pattern.recompile_pattern(pid, keyword_list)

end
