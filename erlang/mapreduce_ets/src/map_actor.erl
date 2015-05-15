-module(map_actor).

-export([map/3]).

map(Parent, Ref, File) ->
	case file:read_file(File) of
		{ok, Binary} ->
			ok = tweet_parser:parse(Binary),
			Parent ! Ref;
		{error, Reason} ->
			erlang:error(Reason)
	end.
