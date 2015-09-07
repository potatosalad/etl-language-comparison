defmodule MatchMapActor do
  def map(file) do
    newline_pattern = :binary.compile_pattern("\n")
    knicks_pattern = :binary.compile_pattern(Utils.permute_case("knicks"))
    tab_pattern = :binary.compile_pattern("\t")

    # Load the whole file in memory and work with offsets
    reduce_file(File.read!(file), HashDict.new,
                newline_pattern, tab_pattern, knicks_pattern)
  end

  def reduce_file(binary, dict, newline, tab, pattern) do
    case :binary.match(binary, pattern) do
      {pos, _} ->
        hood = find_hood(binary, tab, pos, 280) # 1 tweet = ~140 characters
        dict = HashDict.update(dict, hood, 1, &(&1 + 1))
        case :binary.match(binary, newline, scope: {pos, byte_size(binary) - pos}) do
          {newpos, _} ->
            rest = :binary.part(binary, newpos + 1, byte_size(binary) - newpos - 1)
            reduce_file(rest, dict, newline, tab, pattern)
          :nomatch ->
            dict
        end
      :nomatch ->
        dict
    end
  end

  defp find_hood(binary, tab, pos, lookbehind) when pos > lookbehind do
    case :binary.matches(binary, tab, scope: {pos - lookbehind, lookbehind}) do
      [] ->
        :erlang.error(:badarg)
      matches ->
        [{a, _}, {b, _}] = :lists.nthtail(length(matches) - 3, :lists.droplast(matches))
        String.to_atom :binary.part(binary, a + 1, b - a - 1)
    end
  end
  defp find_hood(binary, tab, pos, _) do
    case :binary.matches(binary, tab, scope: {0, pos}) do
      [] ->
        :erlang.error(:badarg)
      matches ->
        [{a, _}, {b, _}] = :lists.nthtail(length(matches) - 3, :lists.droplast(matches))
        String.to_atom :binary.part(binary, a + 1, b - a - 1)
    end
  end
end
