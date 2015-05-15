-module(tweet_parser).

-export([parse/2]).

parse(<<>>, _SendOutput) ->
	ok;
parse(Binary, SendOutput) ->
	parse_tweet(Binary, SendOutput).

parse_tweet(<< $\t, Rest/binary >>, SendOutput) ->
	parse_tweet_hood(Rest, <<>>, SendOutput);
parse_tweet(<< _, Rest/binary >>, SendOutput) ->
	parse_tweet(Rest, SendOutput);
parse_tweet(<<>>, _SendOutput) ->
	ok.

parse_tweet_hood(<< $\t, Rest/binary >>, Hood, SendOutput) ->
	parse_next_tab(Rest, Hood, SendOutput);
parse_tweet_hood(<< $\n, Rest/binary >>, _Hood, SendOutput) ->
	parse(Rest, SendOutput);
parse_tweet_hood(<< C, Rest/binary >>, Hood, SendOutput) ->
	parse_tweet_hood(Rest, << Hood/binary, C >>, SendOutput);
parse_tweet_hood(<<>>, _Hood, _SendOutput) ->
	ok.

parse_next_tab(<< $\t, Rest/binary >>, Hood, SendOutput) ->
	parse_tweet_message(Rest, Hood, SendOutput);
parse_next_tab(<< $\n, Rest/binary >>, _Hood, SendOutput) ->
	parse(Rest, SendOutput);
parse_next_tab(<< _, Rest/binary >>, Hood, SendOutput) ->
	parse_next_tab(Rest, Hood, SendOutput);
parse_next_tab(<<>>, _Hood, _SendOutput) ->
	ok.

parse_tweet_message(<< K, Rest/binary >>, Hood, SendOutput)
		when (K =:= $K orelse K =:= $k) ->
	parse_tweet_message_match(Rest, Hood, SendOutput);
parse_tweet_message(<< $\n, Rest/binary >>, _Hood, SendOutput) ->
	parse(Rest, SendOutput);
parse_tweet_message(<< _, Rest/binary >>, Hood, SendOutput) ->
	parse_tweet_message(Rest, Hood, SendOutput);
parse_tweet_message(<<>>, _Hood, _SendOutput) ->
	ok.

parse_tweet_message_match(<< N, I, C, K, S, Rest/binary >>, Hood, SendOutput)
		when (N =:= $N orelse N =:= $n)
		andalso (I =:= $I orelse I =:= $i)
		andalso (C =:= $C orelse C =:= $c)
		andalso (K =:= $K orelse K =:= $k)
		andalso (S =:= $S orelse S =:= $s) ->
	SendOutput({Hood, 1}),
	parse_next_line(Rest, SendOutput);
parse_tweet_message_match(Rest, Hood, SendOutput) ->
	parse_tweet_message(Rest, Hood, SendOutput).

parse_next_line(<< $\n, Rest/binary >>, SendOutput) ->
	parse(Rest, SendOutput);
parse_next_line(<< _, Rest/binary >>, SendOutput) ->
	parse_next_line(Rest, SendOutput);
parse_next_line(<<>>, _SendOutput) ->
	ok.
