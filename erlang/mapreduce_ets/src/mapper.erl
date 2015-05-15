-module(mapper).

-export([map/1]).

map(InputDir) ->
	case file:list_dir(InputDir) of
		{ok, Filenames} ->
			map_actors([filename:join(InputDir, Filename) || Filename <- Filenames]);
		{error, Reason} ->
			erlang:error(Reason)
	end.

map_actors(Files) ->
	spawn_map_actors(Files, make_ref(), 0).

spawn_map_actors([File | Files], Ref, N) ->
	case filelib:is_file(File) of
		false ->
			spawn_map_actors(Files, Ref, N);
		true ->
			spawn_link(map_actor, map, [self(), Ref, File]),
			spawn_map_actors(Files, Ref, N+1)
	end;
spawn_map_actors([], Ref, N) ->
	receive_map_actors(N, Ref).

receive_map_actors(0, _Ref) ->
	ok;
receive_map_actors(N, Ref) ->
	receive
		Ref ->
			receive_map_actors(N-1, Ref)
	end.
