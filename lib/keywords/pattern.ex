defmodule Keywords.Pattern do
  use Agent

  # data = %{
  #  pattern: pattern,
  #  keyword_list: keyword_list, ?????
  #  keywords_map: keywords_map,
  #  options: opts
  #}

  def start_link([name, data]),
      do: Agent.start_link(fn -> data end, name: name)

  def get(pid),
      do: Agent.get(pid, fn data -> data end)

  def update(pid, new_data),
      do: Agent.update(pid, fn _data -> new_data end)

end
