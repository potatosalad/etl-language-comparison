-module(tweet_parser).

-export([parse/1]).

-define(TABLE, mapreduce).

parse(<<>>) ->
	ok;
parse(Binary) ->
	parse_tweet(Binary).

parse_tweet(<< $\t, Rest/binary >>) ->
	parse_tweet_hood(Rest, <<>>);
parse_tweet(<< _, Rest/binary >>) ->
	parse_tweet(Rest);
parse_tweet(<<>>) ->
	ok.

parse_tweet_hood(<< $\t, Rest/binary >>, Hood) ->
	parse_next_tab(Rest, Hood);
parse_tweet_hood(<< $\n, Rest/binary >>, _Hood) ->
	parse(Rest);
parse_tweet_hood(<< C, Rest/binary >>, Hood) ->
	parse_tweet_hood(Rest, << Hood/binary, C >>);
parse_tweet_hood(<<>>, _Hood) ->
	ok.

parse_next_tab(<< $\t, Rest/binary >>, Hood) ->
	parse_tweet_message(Rest, Hood);
parse_next_tab(<< $\n, Rest/binary >>, _Hood) ->
	parse(Rest);
parse_next_tab(<< _, Rest/binary >>, Hood) ->
	parse_next_tab(Rest, Hood);
parse_next_tab(<<>>, _Hood) ->
	ok.

parse_tweet_message(<< K, Rest/binary >>, Hood)
		when (K =:= $K orelse K =:= $k) ->
	parse_tweet_message_match(Rest, Hood);
parse_tweet_message(<< $\n, Rest/binary >>, _Hood) ->
	parse(Rest);
parse_tweet_message(<< _, Rest/binary >>, Hood) ->
	parse_tweet_message(Rest, Hood);
parse_tweet_message(<<>>, _Hood) ->
	ok.

parse_tweet_message_match(<< N, I, C, K, S, Rest/binary >>, Hood)
		when (N =:= $N orelse N =:= $n)
		andalso (I =:= $I orelse I =:= $i)
		andalso (C =:= $C orelse C =:= $c)
		andalso (K =:= $K orelse K =:= $k)
		andalso (S =:= $S orelse S =:= $s) ->
	ets:insert_new(?TABLE, {Hood, 0}),
	ets:update_counter(?TABLE, Hood, 1),
	parse_next_line(Rest);
parse_tweet_message_match(Rest, Hood) ->
	parse_tweet_message(Rest, Hood).

parse_next_line(<< $\n, Rest/binary >>) ->
	parse(Rest);
parse_next_line(<< _, Rest/binary >>) ->
	parse_next_line(Rest);
parse_next_line(<<>>) ->
	ok.
