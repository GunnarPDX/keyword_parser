defmodule Keywords do
  @moduledoc """
  Documentation for `KeywordParser`.
  """

  alias Keywords.Pattern
  alias Keywords.PatternSupervisor

  @doc """
  Generates new keyword-pattern for parsing strings from a list of keywords.

  opts
  -> case_sensitive: true/false
  -> substrings: true/false
  defaults -> case_sensitive: false, substrings: false

  ## Examples
      iex> Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      {:ok, :stocks}
      iex> Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      {:error, :already_started}
  """
  @new_pattern_defaults %{substrings: false, case_sensitive: false}

  def new_pattern(name, keyword_list, opts \\ [])
  def new_pattern(:all, _, _), do: {:error, :reserved_pattern_name}
  def new_pattern(nil, _, _), do: {:error, :invalid_pattern_name}
  def new_pattern(_, nil, _), do: {:error, :invalid_keywords}
  # {:error, :pattern_not_found}

  def new_pattern(name, keyword_list, opts) when is_list(keyword_list) do
    opts = Enum.into(opts, @new_pattern_defaults)

    pattern =
      keyword_list
      |> add_case_variants(opts)
      |> :binary.compile_pattern()

    keywords_map = Enum.into(keyword_list, %{}, fn kw -> {String.downcase(kw), kw} end)

    data = %{
      pattern: pattern,
      keywords_map: keywords_map,
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
        _err -> {:error, :pattern_not_found}
    end
  end

  @doc """
  Checks if pattern exists.

  ## Examples
      iex> Keywords.pattern_exists?(:stocks)
      true
      iex> Keywords.pattern_exists?(:stonks)
      false
  """
  def pattern_exists?(name) do
    Registry.lookup(PatternRegistry, name) != []
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
  def parse(nil, _, _), do: {:ok, []}
  def parse(_, nil, _), do: {:error, :pattern_not_found}

  def parse(string, pattern_names, opts) when is_list(pattern_names) do
    opts = Enum.into(opts, @parse_defaults)

    # remove non utf-8 chars
    string = strip_utf(string)

    result_sets =
      pattern_names
      |> Enum.map(fn name -> name end) # via registry_tuple...
      |> Enum.map(fn name -> get_pattern_matches(name, string) end)
      |> Enum.reduce({[], []}, fn
          {:ok, {name, result}}, {results, errors} ->
            {[{name, result} | results], errors}

          {:error, name}, {results, errors} ->
            {results, [errors | name]}
        end)

    case result_sets do
      {results, []} ->
        matches = process_multi_pattern_opts(results, opts)
        {:ok, matches}

      {_results, missing_patterns} ->
        {:error, %{patterns_not_found: missing_patterns}}
    end
  end

  def parse(string, :all, opts) do
    case Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}]) do
      [] ->
        {:error, :no_patterns_available}

      pattern_names ->
        parse(string, pattern_names, opts)
    end
  end

  def parse(string, pattern_name, opts) do
    opts = Enum.into(opts, @parse_defaults)

    # remove non utf-8 chars
    string = strip_utf(string)

    case get_pattern_matches(pattern_name, string) do
      {:ok, {_name, result}} ->
        matches = process_single_pattern_opts(result, opts)
        {:ok, matches}

      {:error, name} ->
        {:error, %{patterns_not_found: name}}
    end
  end

  # @doc false
  # def recompile_pattern(pid, keyword_list) do
  #   :binary.compile_pattern(keyword_list)
  #   Pattern.recompile_pattern(pid, keyword_list)
  # end

  defp process_single_pattern_opts(result, opts) do
    case opts do
      %{counts: true} ->
        result
        |> Enum.frequencies()
        |> Map.to_list()

      %{counts: false} ->
        Enum.uniq(result)
    end
  end

  defp process_multi_pattern_opts(result_sets, opts) do
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

  defp via_registry_tuple(name), do: {:via, Registry, {PatternRegistry, name}}
  # defp from_registry_tuple({:via, _, {_, name}}), do: name

  defp get_pattern_matches(name, string) do
    case Registry.lookup(PatternRegistry, name) do
      [{pid, _}] ->
        %{pattern: pattern, keywords_map: keywords_map, options: opts} = Pattern.get(pid)

        string
        |> :binary.matches(pattern)
        |> pull_matches(name, string, keywords_map, opts)

      [] ->
        {:error, name}
    end
  end

  defp pull_matches(bit_matches, name, string, keywords_map, pattern_opts) do
    case pattern_opts do
      %{substrings: false, case_sensitive: false} ->
        get_full_string_matches(name, string, bit_matches)
        |> get_original_keyword_case(keywords_map)

      %{substrings: false, case_sensitive: true} ->
        get_full_string_matches(name, string, bit_matches)

      %{substrings: true, case_sensitive: true} ->
        get_any_matches(name, string, bit_matches)
        |> get_original_keyword_case(keywords_map)

      %{substrings: true, case_sensitive: false} ->
        get_any_matches(name, string, bit_matches)

    end
  end

  defp get_full_string_matches(name, string, bit_matches) do
    case Parser.find_matches(bit_matches, string) do
      {:ok, keywords} ->
        {:ok, {name, keywords}}

      _ ->
        {:error, name}
    end
  end

  defp get_any_matches(name, string, bit_matches) do
    keywords = Enum.map(bit_matches, fn bit_match -> :binary.part(string, bit_match) end)
    {:ok, {name, keywords}}
  end

  defp get_original_keyword_case({:error, _name} = err, _), do: err
  defp get_original_keyword_case({:ok, {name, keywords}}, keywords_map) do
    keywords = Enum.map(keywords, fn keyword -> keywords_map[String.downcase(keyword)] end)
    {:ok, {name, keywords}}
  end

  defp strip_utf(str) do
    strip_utf_helper(str, [])
  end

  defp strip_utf_helper(<<x :: utf8>> <> rest, acc) when x <= 127 do
    strip_utf_helper rest, [x | acc]
  end

  defp strip_utf_helper(<<_>> <> rest, acc), do: strip_utf_helper(rest, acc)

  defp strip_utf_helper("", acc) do
    acc
    |> :lists.reverse
    |> List.to_string
  end

  defp add_case_variants(keyword_list, %{case_sensitive: true}), do: keyword_list
  defp add_case_variants(keyword_list, %{case_sensitive: false}) do
    uppercase_keyword_list = Enum.map(keyword_list, fn kw -> String.upcase(kw) end)
    lowercase_keyword_list = Enum.map(keyword_list, fn kw -> String.downcase(kw) end)
    capitalized_keyword_list = Enum.map(lowercase_keyword_list, fn kw -> String.capitalize(kw) end)

    uppercase_keyword_list ++ lowercase_keyword_list ++ capitalized_keyword_list
  end


end
