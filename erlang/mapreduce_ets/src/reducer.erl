-module(reducer).

-export([reduce/1]).

-define(TABLE, mapreduce).

reduce(Destination) ->
	Final = lists:sort(fun
		({K1, V}, {K2, V}) ->
			K1 =< K2;
		({_, V1}, {_, V2}) ->
			V1 >= V2
	end, ets:tab2list(?TABLE)),
	Output = << << K/binary, $\t, (integer_to_binary(V))/binary, $\n >> || {K, V} <- Final >>,
	file:write_file(Destination, Output).
