defmodule SplitMapActor do
  def map(file) do
    newline_pattern = :binary.compile_pattern("\n")
    knicks_pattern = :binary.compile_pattern(Utils.permute_case("knicks"))
    tab_pattern = :binary.compile_pattern("\t")

    # Load the whole file in memory and work with offsets
    reduce_file(File.read!(file), HashDict.new,
                newline_pattern, tab_pattern, knicks_pattern)
  end

  def reduce_file(binary, dict, newline, tab, pattern) do
    case :binary.split(binary, newline) do
      [_] ->
        dict
      [line, rest] ->
        dict =
          case :binary.match(line, pattern) do
            {pos, _} ->
              [_, hood | _] = :binary.split(line, tab, [:global, scope: {0, pos}])
              hood = String.to_atom hood
              HashDict.update(dict, hood, 1, &(&1 + 1))
            :nomatch ->
              dict
          end

        reduce_file(rest, dict, newline, tab, pattern)
    end
  end
end
