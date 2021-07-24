defmodule Keywords.Pattern do
  use Agent

  # data = %{
  #  pattern: pattern,
  #  keyword_list: keyword_list,
  #  options: opts
  #}

  def start_link([name, data]),
      do: Agent.start_link(fn -> data end, name: name)

  def get(pid),
      do: Agent.get(pid, fn data -> data end)

  # def recompile_pattern(pid, keyword_list) do
  #   pattern = compile_pattern(keyword_list)
  #   Agent.update(pid, fn data -> %{new_pattern...} end)
  # end

end