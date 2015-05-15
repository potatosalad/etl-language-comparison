-module(mapreduce).

-export([main/1]).
-export([start/0]).

main(_) ->
	?MODULE = ets:new(?MODULE, [
		named_table,
		public,
		ordered_set,
		{read_concurrency, true},
		{write_concurrency, true}
	]),
	ok = mapper:map("../../tmp/tweets/"),
	ok = reducer:reduce("../../tmp/erlang_ets_output"),
	true = ets:delete(?MODULE),
	erlang:halt(0).

start() ->
	main([]).
