-module(mapreduce).

-include_lib("riak_pipe/include/riak_pipe.hrl").

-export([main/1]).
-export([start/0]).

main(_) ->
	Spec = [
		#fitting_spec{
			name=map,
			module=riak_pipe_w_xform,
			arg=fun map/3
		},
		#fitting_spec{
			name=reduce,
			module=riak_pipe_w_reduce,
			arg=fun reduce/4,
			chashfun=fun riak_pipe_w_reduce:chashfun/1
		}
	],
	{ok, Pipe} = riak_pipe:exec(Spec, []),
	riak_core:wait_for_service(riak_pipe),
	Input = "../../tmp/tweets/",
	ok = case file:list_dir(Input) of
		{ok, Filenames} ->
			_ = [begin
				riak_pipe:queue_work(Pipe, File)
			end || File <- [filename:join(Input, Filename) || Filename <- Filenames], filelib:is_file(File)],
			ok;
		{error, Reason} ->
			erlang:error(Reason)
	end,
	riak_pipe:eoi(Pipe),
	{eoi, Results, _} = riak_pipe:collect_results(Pipe, 100000),
	Final = lists:sort(fun
		({K1, V}, {K2, V}) ->
			K1 =< K2;
		({_, V1}, {_, V2}) ->
			V1 >= V2
	end, [{Key, Value} || {reduce, {Key, [Value]}} <- Results]),
	Output = << << K/binary, $\t, (integer_to_binary(V))/binary, $\n >> || {K, V} <- Final >>,
	file:write_file("../../tmp/erlang_riak_pipe_output", Output),
	erlang:halt(0).

start() ->
	error_logger:tty(false),
	application:load(sasl),
	application:set_env(sasl, sasl_error_logger, false),
	application:load(riak_core),
	application:set_env(riak_core, ring_state_dir, "./data/ring"),
	application:set_env(riak_core, schema_dirs, ["./deps/riak_core/priv", "./deps/riak_sysmon/priv"]),
	application:load(lager),
	application:set_env(lager, handlers, []),
	application:set_env(lager, crash_log, undefined),
	application:set_env(lager, error_logger_redirect, false),
	application:ensure_all_started(mapreduce_riak_pipe),
	lager:set_loglevel(lager_console_backend, error),
	main([]).

map(Input, Partition, FittingDetails) ->
	case file:read_file(Input) of
		{ok, Binary} ->
			SendOutput = fun(Output) ->
				riak_pipe_vnode_worker:send_output(Output, Partition, FittingDetails)
			end,
			tweet_parser:parse(Binary, SendOutput);
		{error, Reason} ->
			erlang:error(Reason)
	end.

reduce(_Key, Value, _Partition, _FittingDetails) ->
	{ok, [lists:sum(Value)]}.
