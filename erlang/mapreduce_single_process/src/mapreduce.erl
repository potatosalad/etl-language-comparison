-module(mapreduce).

-export([main/1]).
-export([start/0]).

main(_) ->
	Mappings = mapper:map("../../tmp/tweets/"),
	ok = reducer:reduce(Mappings, "../../tmp/erlang_single_process_output"),
	erlang:halt(0).

start() ->
	main([]).
