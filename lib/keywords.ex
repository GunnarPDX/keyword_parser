defmodule Keywords do
  @moduledoc """
  Documentation for `KeywordParser`.
  """

  alias Keywords.Pattern
  alias Keywords.PatternSupervisor

  # Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
  # Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks)
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :all)
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks, [counts: true])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true, aggregate: false])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [aggregate: false])
  # Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

  @doc """
  Generates new keyword list pattern for parsing strings.
  """
  def new_pattern(name, keyword_list) do
    name = via_registry_tuple(name)

    DynamicSupervisor.start_child(PatternSupervisor, {Pattern, [name, keyword_list]})
  end

  @doc """
  Parses tickers from string

  ## Examples
      Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stock_tickers)
      [XOM, AAPL, TSLA, PLTR, AMZN]
  """
  @parse_defaults %{counts: false, aggregate: true}

  def parse(string, pattern_names, opts \\ [])
  def parse(nil, _, _), do: nil
  def parse(_, nil, _), do: nil

  def parse(string, pattern_names, opts) when is_list(pattern_names) do
    opts = Enum.into(opts, @parse_defaults)

    result_sets =
      pattern_names
      |> Enum.map(fn name -> via_registry_tuple(name) end)
      |> Enum.map(fn name -> get_matches(name, string) end)


    case opts do
      %{counts: true, aggregate: true} ->
        result_sets
        |> Enum.flat_map(fn {_k, set} -> set end)
        |> Enum.frequencies()
        |> Map.to_list()

      %{counts: false, aggregate: true} ->
        result_sets
        |> Enum.flat_map(fn {_k, set} -> set end)
        |> Enum.uniq()

      %{counts: true, aggregate: false} ->
        result_sets
        |> Enum.map(fn {k, set} -> {k, Enum.frequencies(set) |> Map.to_list()} end)

      %{counts: false, aggregate: false} ->
        result_sets
        |> Enum.map(fn {k, set} -> {k, Enum.uniq(set)} end)
    end
  end

  def parse(string, :all, opts) do
    pattern_names = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

    parse(string, pattern_names, opts)
  end

  def parse(string, pattern_name, opts) when is_atom(pattern_name) do
    opts = Enum.into(opts, @parse_defaults)

    {_name, result} =
      pattern_name
      |> via_registry_tuple()
      |> get_matches(string)

    case opts do
      %{counts: true} ->
        result
        |> Enum.frequencies()
        |> Map.to_list()

      %{counts: false} ->
        Enum.uniq(result)
    end
  end

  @doc """
  Recompiles keyword pattern.
  """
  def recompile(pid, keyword_list), do: Pattern.recompile_pattern(pid, keyword_list)

  defp via_registry_tuple(name), do: {:via, Registry, {PatternRegistry, name}}

  defp from_registry_tuple({:via, _, {_, name}}), do: name

  defp get_matches(name, string) do
    pattern = Pattern.get(name)

    result =
      string
      |> :binary.matches(pattern)
      |> Enum.map(fn bit_match -> :binary.part(string, bit_match) end)

    {from_registry_tuple(name), result}
  end


end
