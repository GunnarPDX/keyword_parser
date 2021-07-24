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
  @new_pattern_defaults %{substrings: false, case_sensitive: false, prefix_characters: [], postfix_characters: []}

  def new_pattern(name, keyword_list, opts \\ [])
  def new_pattern(:all, _, _), do: {:error, :reserved_name}

  def new_pattern(name, keyword_list, opts) do
    # TODO: store original keywords and opts in pattern agent.

    opts = Enum.into(opts, @new_pattern_defaults)

    pattern =
      keyword_list
      |> add_case_variants(opts)
      |> add_prefix_characters(opts)
      |> add_postfix_characters(opts)
      |> prevent_substring_matches(opts)
      |> :binary.compile_pattern()

    data = %{
      pattern: pattern,
      keyword_list: keyword_list,
      options: opts
    }

    registry_name = via_registry_tuple(name)

    case DynamicSupervisor.start_child(PatternSupervisor, {Pattern, [registry_name, data]}) do
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
  def recompile_pattern(pid, keyword_list) do
    # :binary.compile_pattern(keyword_list)
    Pattern.recompile_pattern(pid, keyword_list)
  end

  defp via_registry_tuple(name), do: {:via, Registry, {PatternRegistry, name}}

  defp from_registry_tuple({:via, _, {_, name}}), do: name

  defp get_matches(name, string) do
    %{pattern: pattern} = Pattern.get(name)

    result =
      string
      |> :binary.matches(pattern)
      |> Enum.map(fn bit_match -> :binary.part(string, bit_match) end)

    {from_registry_tuple(name), result}
  end

  defp add_prefix_characters(keyword_list, %{prefix_characters: []}), do: keyword_list
  defp add_prefix_characters(keyword_list, %{prefix_characters: pre_chars}) do
    prefix_variants = for kw <- keyword_list, pc <- pre_chars do
      pc <> kw
    end

    prefix_variants ++ keyword_list
  end

  defp add_postfix_characters(keyword_list, %{postfix_characters: []}), do: keyword_list
  defp add_postfix_characters(keyword_list, %{postfix_characters: post_chars}) do
    postfix_variants = for kw <- keyword_list, pc <- post_chars do
      kw <> pc
    end

    postfix_variants ++ keyword_list
  end

  defp prevent_substring_matches(keyword_list, %{substrings: true}), do: keyword_list
  defp prevent_substring_matches(keyword_list, %{substrings: false}) do
    Enum.map(keyword_list, fn kw -> " " <> String.trim(kw) <> " " end)
  end

  defp add_case_variants(keyword_list, %{case_sensitive: true}), do: keyword_list
  defp add_case_variants(keyword_list, %{case_sensitive: false}) do
    uppercase_keyword_list = Enum.map(keyword_list, fn kw -> String.upcase(kw) end)
    lowercase_keyword_list = Enum.map(keyword_list, fn kw -> String.downcase(kw) end)
    capitalized_keyword_list = Enum.map(lowercase_keyword_list, fn kw -> String.capitalize(kw) end)

    uppercase_keyword_list ++ lowercase_keyword_list ++ capitalized_keyword_list
  end


end
