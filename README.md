# Distro


This example was inspired(rewritten) by these blog posts

https://erlangcentral.org/topic/elixir-application-failovertakeover/

https://dockyard.com/blog/2016/01/28/running-elixir-and-phoenix-projects-on-a-cluster-of-nodes

## Start single node
```
iex --sname abc -pa _build/dev/lib/distro/ebin --app distro
# Test server
Distro.DistroCal.add(4,5)
```


## Start all 3 nodes

You could use __Tmux__ for this ;o)

_Terminal 1_

`iex --name one@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/one" -S mix`

_Terminal 2_

`iex --name two@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/two" -S mix`

_Terminal 3_

`iex --name three@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/three" -S mix`


## Play with take over

Shut down(ctrl-c) Node _one_ and see the GenServer start on node _two_ or _three_

In the example below it's node `three@127.0.0.1` taking over

Example output, node `three@127.0.0.1` terminal
```
15:57:28.955 [info]  Distro application in :normal mode
15:57:28.955 [info]  Starting server
```

Try and execute the function below on both running nodes and see what happens
`Distro.DistroCal.add(4,5)`

Start node `one@127.0.0.1` again

Example output, node `three@127.0.0.1` terminal
```
15:58:07.134 [info]  Application distro exited: :stopped
```


Example output, node `one@127.0.0.1` terminal
```
iex --name one@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/one"
15:58:07.132 [info]  Distro application in {:takeover, :"three@127.0.0.1"} mode
15:58:07.133 [info]  Starting server
```

 Run `Distro.DistroCal.add(4,5)` again
