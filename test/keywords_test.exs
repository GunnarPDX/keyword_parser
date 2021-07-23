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


  describe "new_pattern" do
    test "create new pattern" do
      result = Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      assert result == {:ok, {:via, Registry, {PatternRegistry, :stocks}}}
    end

    test "create multiple patterns" do
      result_1 = Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      result_2 = Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      assert result_1 == {:ok, {:via, Registry, {PatternRegistry, :stocks_1}}}
      assert result_2 == {:ok, {:via, Registry, {PatternRegistry, :stocks_2}}}

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])

      assert registry = [:stocks_1, :stocks_2]
    end

    test "wont create pattern named :all" do
      result = Keywords.new_pattern(:all, ["TSLA", "XOM", "AMZN"])
      assert result == {:error, :reserved_name}
    end
  end

  describe "kill_pattern" do
    test "kill single pattern" do
      result = Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry = [:stocks]

      Keywords.kill_pattern(:stocks)

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry = []
    end

    test "kill multiple patterns" do
      result_1 = Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      result_2 = Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry = [:stocks_1, :stocks_2]

      Keywords.kill_pattern(:stocks_1)

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry = [:stocks_2]

      Keywords.kill_pattern(:stocks_2)

      registry = Registry.select(PatternRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
      assert registry = []
    end
  end

  describe "parse" do
    test "simple usage" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks_1)
      assert result == ["XOM", "TSLA", "AMZN"]

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks_2)
      assert result == ["AAPL", "PLTR"]
    end

    test "simple no matches" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      result = Keywords.parse("a|n[xwn;qw%dl$qm*w", :stocks)
      assert result == []
    end

    test "no content" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])
      result = Keywords.parse(nil, :stocks)
      assert result == []
    end

    test "non existent pattern" do
      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :qwertyuiop)
      assert result == []
    end

    test "nil pattern" do
      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", nil)
      assert result == []
    end

    test "multiple patterns" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2])
      assert result == ["AAPL", "PLTR", "XOM", "TSLA", "PLTR", "AMZN"]
    end

    test ":all patterns" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :all)
      assert result == ["XOM", "AMZN", "TSLA", "AAPL", "PLTR"]
    end

    test "single pattern with counts" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", :stocks, [counts: true])
      assert result == [{"AMZN", 2}, {"TSLA", 1}, {"XOM", 1}]
    end

    test "multiple patterns with counts" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks, :stocks_2], [counts: true])
      assert result == [{"AAPL", 1}, {"AMZN", 2}, {"PLTR", 1}, {"TSLA", 1}, {"XOM", 1}]
    end

    test "multiple without aggregation" do
      Keywords.new_pattern(:stocks_1, ["TSLA", "XOM", "AMZN"])
      Keywords.new_pattern(:stocks_2, ["PLTR", "AAPL"])

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2], [counts: true, aggregate: false])
      assert result == [stocks_1: [{"AMZN", 2}, {"TSLA", 1}, {"XOM", 1}], stocks_2: [{"AAPL", 1}, {"PLTR", 1}]]

      result = Keywords.parse(" XOM AAPL AMZN $TSLA buy now, ++ PLTR and $AMZN", [:stocks_1, :stocks_2], [aggregate: false])
      assert result == [stocks_1: ["AMZN", "TSLA", "XOM"], stocks_2: ["AAPL", "PLTR"]]
    end

    test "single without aggregation" do
      Keywords.new_pattern(:stocks, ["TSLA", "XOM", "AMZN"])

      result = Keywords.parse(" XOM AAPL $TSLA buy now, ++ PLTR and $AMZN", :stocks, [aggregate: false])
      assert result == ["TSLA", "XOM", "AMZN"]
    end
  end

end
