defmodule Keywords do
  @moduledoc """
  Documentation for `KeywordParser`.
  """

  alias Keywords.Pattern
  alias Keywords.PatternSupervisor

  @doc """
  Generates new keyword-pattern for parsing strings from a list of keywords.

  ## Examples
      iex> Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      {:ok, :stocks}
      iex> Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      {:error, :already_started}
  """
  def new_pattern(name, keyword_list) do
    name = via_registry_tuple(name)

    case DynamicSupervisor.start_child(PatternSupervisor, {Pattern, [name, keyword_list]}) do
      {:ok, _pid} -> {:ok, name}
      {:error, {:already_started, _pid}} -> {:error, :already_started}
      err -> err
    end
  end

  @doc """
  Removes pattern by name.

  ## Examples
      iex> Keywords.kill_pattern(:stocks)
      {:ok, :stocks}
      iex> Keywords.kill_pattern(:stocks)
      {:error, :not_found}
  """
  def kill_pattern(name) do
    result = Registry.lookup(PatternRegistry, name) |> List.first()

    with {pid, _} <- result,
         :ok <- DynamicSupervisor.terminate_child(PatternSupervisor, pid)
      do
        {:ok, name}
      else
        err -> {:error, :not_found}
    end
  end

  @doc """
  Parses tickers from string

  opts
  -> counts: true/false (include total occurrences of each keyword)
  -> aggregate: true/false (group results by pattern name)
  defaults -> counts: false, aggregate: true

  ## Examples
      iex> Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks)
      [XOM, AAPL, TSLA, PLTR, AMZN]

      iex> Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks_2)
      ["AAPL", "PLTR"]

      iex> Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2])
      ["AAPL", "PLTR", XOM, TSLA, PLTR, AMZN]

      iex> Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :all)
      ["XOM", "AMZN", "TSLA", "AAPL", "PLTR"]

      iex> Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks, [counts: true])
      [{"AMZN", 2}, {"TSLA", 1}, {"XOM", 1}]

      iex> Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true])
      [{"AAPL", 1}, {"AMZN", 2}, {"PLTR", 1}, {"TSLA", 1}, {"XOM", 1}]

      iex> Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true, aggregate: false])
      [stocks: [{"AMZN", 2}, {"TSLA", 1}, {"XOM", 1}], stocks_2: [{"AAPL", 1}, {"PLTR", 1}]]

      iex> Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [aggregate: false])
      [stocks: ["XOM", "AMZN", "TSLA"], stocks_2: ["AAPL", "PLTR"]]

      iex> Keywords.parse("a|n[xwn;qw%dl$qm*w", :stocks)
      []

      iex> Keywords.parse(nil, :stocks)
      []

  """
  @parse_defaults %{counts: false, aggregate: true}
  def parse(string, pattern_names, opts \\ [])
  def parse(nil, _, _), do: []
  def parse(_, nil, _), do: []

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

  @doc false
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
