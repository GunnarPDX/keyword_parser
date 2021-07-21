defmodule Keywords do
  @moduledoc """
  Documentation for `KeywordParser`.
  """

  alias Keywords.Pattern
  alias Keywords.PatternSupervisor

  # Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
  # Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks)
  # Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

  @doc """
  Generates new keyword list pattern for parsing strings.
  """
  def new_pattern(name, keyword_list) do
    name = via_tuple(name)

    DynamicSupervisor.start_child(PatternSupervisor, {Pattern, [name, keyword_list]})
  end

  @doc """
  Parses tickers from string

  ## Examples
      Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stock_tickers)
      [XOM, AAPL, TSLA, PLTR, AMZN]
  """
  # TODO: make pattern_name as string?
  def parse(nil, _, _), do: []
  def parse(string, pattern_name, opts \\ []) do
    pattern_name = via_tuple(pattern_name)

    pattern = Pattern.get(pattern_name)
    bit_matches = :binary.matches(string, pattern)
    bit_matches = for x <- bit_matches, do: :binary.part(string, x)

    Enum.uniq(bit_matches)
  end

  @doc """
  Recompiles keyword pattern.
  """
  def recompile(pid, keyword_list), do: Pattern.recompile_pattern(pid, keyword_list)

  @doc false
  defp via_tuple(name), do: {:via, Registry, {PatternRegistry, name}}


end
