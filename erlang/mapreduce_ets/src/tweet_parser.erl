-module(tweet_parser).

-export([parse/1]).

-define(TABLE, mapreduce).

-define(SEARCH, [
	<<"knicks">>,<<"Knicks">>,<<"kNicks">>,<<"KNicks">>,
	<<"knIcks">>,<<"KnIcks">>,<<"kNIcks">>,<<"KNIcks">>,
	<<"kniCks">>,<<"KniCks">>,<<"kNiCks">>,<<"KNiCks">>,
	<<"knICks">>,<<"KnICks">>,<<"kNICks">>,<<"KNICks">>,
	<<"knicKs">>,<<"KnicKs">>,<<"kNicKs">>,<<"KNicKs">>,
	<<"knIcKs">>,<<"KnIcKs">>,<<"kNIcKs">>,<<"KNIcKs">>,
	<<"kniCKs">>,<<"KniCKs">>,<<"kNiCKs">>,<<"KNiCKs">>,
	<<"knICKs">>,<<"KnICKs">>,<<"kNICKs">>,<<"KNICKs">>,
	<<"knickS">>,<<"KnickS">>,<<"kNickS">>,<<"KNickS">>,
	<<"knIckS">>,<<"KnIckS">>,<<"kNIckS">>,<<"KNIckS">>,
	<<"kniCkS">>,<<"KniCkS">>,<<"kNiCkS">>,<<"KNiCkS">>,
	<<"knICkS">>,<<"KnICkS">>,<<"kNICkS">>,<<"KNICkS">>,
	<<"knicKS">>,<<"KnicKS">>,<<"kNicKS">>,<<"KNicKS">>,
	<<"knIcKS">>,<<"KnIcKS">>,<<"kNIcKS">>,<<"KNIcKS">>,
	<<"kniCKS">>,<<"KniCKS">>,<<"kNiCKS">>,<<"KNiCKS">>,
	<<"knICKS">>,<<"KnICKS">>,<<"kNICKS">>,<<"KNICKS">>
]).

parse(Binary) ->
	parse(Binary, binary:compile_pattern(<< $\n >>), binary:compile_pattern(<< $\t >>), binary:compile_pattern(?SEARCH)).

parse(Binary, Newline, Tab, Search) ->
	case binary:match(Binary, Newline) of
		{Pos, _} ->
			case binary:match(Binary, Search, [{scope, {0, Pos}}]) of
				{_, _} ->
					case binary:match(Binary, Tab) of
						{A, _} ->
							case binary:match(Binary, Tab, [{scope, {A+1, Pos-A-1}}]) of
								{B, _} ->
									Hood = binary:part(Binary, A+1, B-A-1),
									ets:insert_new(?TABLE, {Hood, 0}),
									ets:update_counter(?TABLE, Hood, 1),
									parse(binary:part(Binary, Pos+1, byte_size(Binary)-Pos-1), Newline, Tab, Search);
								_ ->
									erlang:error(badarg)
							end;
						_ ->
							erlang:error(badarg)
					end;
				_ ->
					parse(binary:part(Binary, Pos+1, byte_size(Binary)-Pos-1), Newline, Tab, Search)
			end;
		_ ->
			ok
	end.
