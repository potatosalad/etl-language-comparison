-module(mapper).

-export([map/1]).

map(InputDir) ->
	case file:list_dir(InputDir) of
		{ok, Filenames} ->
			fold([filename:join(InputDir, Filename) || Filename <- Filenames], dict:new());
		{error, Reason} ->
			erlang:error(Reason)
	end.

fold([File | Files], Acc) ->
	case filelib:is_file(File) of
		false ->
			fold(Files, Acc);
		true ->
			case file:read_file(File) of
				{ok, Binary} ->
					fold(Files, tweet_parser:parse(Binary, Acc));
				{error, Reason} ->
					erlang:error(Reason)
			end
	end;
fold([], Acc) ->
	Acc.
