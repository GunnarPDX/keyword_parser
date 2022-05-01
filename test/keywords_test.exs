defmodule KeywordsTest do
  use ExUnit.Case
  #doctest Keywords

  # Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
  # Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks)
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :all)
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks, [counts: true])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true, aggregate: false])
  # Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [aggregate: false])
  # Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

  # Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
  # Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])
  # Keywords.kill_pattern(:stocks)
  # Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])


  setup do
    kill_all_patterns()
  end


  describe "new_pattern" do
    test "create new pattern" do
      result = Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      assert result == {:ok, :stocks}
    end

    test "create multiple patterns" do
      result_1 = Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      result_2 = Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      assert result_1 == {:ok, :stocks_1}
      assert result_2 == {:ok, :stocks_2}

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

      assert registry == [:stocks_2, :stocks_1]
    end

    test "wont create pattern named :all" do
      result = Keywords.new_pattern(:all, ["TSLA", "XOM", "AMZN"])
      assert result == {:error, :reserved_pattern_name}
    end

    test "nil pattern name" do
      result = Keywords.new_pattern(nil, ["TSLA", "XOM", "AMZN"])
      assert result == {:error, :invalid_pattern_name}
    end

    test "nil keywords" do
      result = Keywords.new_pattern(:nothing, nil)
      assert result == {:error, :invalid_keywords}
    end
  end

  describe "kill_pattern" do
    test "kill single pattern" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry == [:stocks]

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      IO.inspect(registry)
      result = Keywords.kill_pattern(:stocks)
      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      IO.inspect(registry)
      assert result == {:ok, :stocks}
      assert registry == []
    end

    test "kill multiple patterns" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry == [:stocks_2, :stocks_1]

      res = Keywords.kill_pattern(:stocks_1)
      assert res == {:ok, :stocks_1}

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry == [:stocks_2]

      res = Keywords.kill_pattern(:stocks_2)
      assert res == {:ok, :stocks_2}

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry == []
    end
  end

  describe "pattern_exists?" do
    test "check if pattern exists" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      result = Keywords.pattern_exists?(:stocks)
      assert result == true

      result = Keywords.pattern_exists?(:stonks)
      assert result == false
    end
  end

  describe "update_pattern" do
    test "ensure pattern update takes effect" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks)
      compare_parse_results(result, ["TSLA", "XOM"])

      Keywords.update_pattern(:stocks, ["AAPL", "PLTR"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks)
      compare_parse_results(result, ["AAPL", "PLTR"])
    end

    test "can't update non-existant pattern" do
      result = Keywords.update_pattern(:stonks, ["AAPL", "PLTR"])
      assert result == {:error, :pattern_not_found}
    end
  end

  describe "parse" do
    test "simple usage" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"], substrings: true)
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])
      Keywords.new_pattern(:stocks_3, ["NVDA", "AMZN", "XOM", "FB"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks_1)
      compare_parse_results(result, ["AMZN", "TSLA", "XOM"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks_2)
      compare_parse_results(result, ["AAPL", "PLTR"])

      result = Keywords.parse(" My favorite picks right now are $NVDA and $AMZN 🚀🚀🚀, but XOM and fb have my attention 🌝", :stocks_3)
      compare_parse_results(result, ["AMZN", "FB", "NVDA", "XOM"])
    end

    test "simple no matches" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      result = Keywords.parse("a|n[xwn;qw%dl$qm*w", :stocks)
      compare_parse_results(result, [])
    end

    test "no content" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      result = Keywords.parse(nil, :stocks)
      compare_parse_results(result, [])
    end

    test "non existent pattern" do
      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :qwertyuiop)
      assert result == {:error, %{patterns_not_found: :qwertyuiop}}
    end

    test "nil pattern" do
      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", nil)
      assert result == {:error, :pattern_not_found}
    end

    test "multiple patterns" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2])
      compare_parse_results(result, ["AAPL", "AMZN", "PLTR", "TSLA", "XOM"])
    end

    test ":all patterns" do
      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :all)
      assert result == {:error, :no_patterns_available}

      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :all)
      compare_parse_results(result, ["AAPL", "AMZN", "PLTR", "TSLA", "XOM"])
    end

    test "single pattern with counts" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks, [counts: true])
      assert result == {:ok, [{"AMZN", 2}, {"TSLA", 1}, {"XOM", 1}]}
    end

    test "multiple patterns with counts" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2], [counts: true])
      assert result == {:ok, [{"AAPL", 1}, {"AMZN", 2}, {"PLTR", 1}, {"TSLA", 1}, {"XOM", 1}]}
    end

    test "multiple without aggregation" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2], [counts: true, aggregate: false])
      assert result == {:ok, [{:stocks_2, [{"AAPL", 1}, {"PLTR", 1}]}, {:stocks_1, [{"AMZN", 2}, {"TSLA", 1}, {"XOM", 1}]}]}

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2], [aggregate: false])
      assert result == {:ok, [{:stocks_2, ["AAPL", "PLTR"]}, {:stocks_1, ["XOM", "AMZN", "TSLA"]}]}
    end

    test "single without aggregation" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks, [aggregate: false])
      compare_parse_results(result, ["AMZN", "TSLA", "XOM"])
    end
  end

  defp compare_parse_results({:ok, result}, valid_result) do
    result = Enum.sort(result)
    valid_result = Enum.sort(valid_result)

    assert result == valid_result
  end

  defp kill_all_patterns do
    Keywords.kill_pattern(:stocks)
    Keywords.kill_pattern(:stocks_1)
    Keywords.kill_pattern(:stocks_2)
    Keywords.kill_pattern(:stocks_3)
    :ok
  end

end
