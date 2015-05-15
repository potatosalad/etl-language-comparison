-module(mapreduce_riak_pipe_app).

-behaviour(application).

-export([start/2]).
-export([stop/1]).

start(_StartType, _StartArgs) ->
	mapreduce_riak_pipe_sup:start_link().

stop(_State) ->
	ok.
