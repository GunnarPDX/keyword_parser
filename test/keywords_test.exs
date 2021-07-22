defmodule KeywordsTest do
  use ExUnit.Case
  doctest Keywords

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

end
