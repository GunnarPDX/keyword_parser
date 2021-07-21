defmodule Keywords.Pattern do
  use Agent

  def start_link([name, keyword_list]) do
    pattern = compile_pattern(keyword_list)

    Agent.start_link(fn -> pattern end, name: name)
  end

  def recompile_pattern(pid, keyword_list) do
    pattern = compile_pattern(keyword_list)

    Agent.update(pid, fn _state -> pattern end)
  end

  def get(pid), do: Agent.get(pid, fn content -> content end)

  defp compile_pattern(keyword_list), do: :binary.compile_pattern(keyword_list)

end