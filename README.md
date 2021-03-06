# Distro


This example was inspired(rewritten) by these blog posts

https://erlangcentral.org/topic/elixir-application-failovertakeover/

https://dockyard.com/blog/2016/01/28/running-elixir-and-phoenix-projects-on-a-cluster-of-nodes


## Terms used


### Node
A __node__ is a BEAM instance, that is a single Erlang Virtual Machine instance.
To start a short named node we execute `iex --sname some_name` or `iex --name some_name@ip_address` to start a long named one.

### Machine
Can be virtual or bare metal.


## System configuration files

There is one config file for each node - one, two and three

Example _config/one.config_
```
[{kernel,
  [{distributed, [{'distro', 5000, ['one@127.0.0.1', {'two@127.0.0.1', 'three@127.0.0.1'}]}]},
   {sync_nodes_mandatory, ['two@127.0.0.1', 'three@127.0.0.1']},
   {sync_nodes_timeout, 30000}
]}].
```

Taken from http://erlang.org/doc/design_principles/distributed_applications.html

`distro` specifies where the application Application = atom() can execute

`5000` specifies how many milliseconds to wait before restarting the application at another node. It defaults to 0.
The failover nodes in this example are these -> `{'two@127.0.0.1', 'three@127.0.0.1'}`.

`sync_nodes_mandatory, ['two@127.0.0.1', 'three@127.0.0.1']` specifies which other nodes must be started (within the time-out specified by sync_nodes_timeout).


`{sync_nodes_timeout, 30000}` specifies how many milliseconds to wait for the other nodes to start


When all nodes are up, or when all mandatory nodes are up and the time specified by sync_nodes_timeout has elapsed, all applications start. If not all mandatory nodes are up, the node terminates.

If `one@127.0.0.1` goes down, the system checks which one of the other nodes, `two@127.0.0.1` or `three@127.0.0.1`, has the least number of running applications, but waits for 5 seconds for `one@127.0.0.1` to restart. If `one@127.0.0.1` does not restart and `two@127.0.0.1` runs fewer applications than `three@127.0.0.1`, __distro__ is restarted on `two@127.0.0.1`.



## Start single node
```
$ iex --sname abc -pa _build/dev/lib/distro/ebin --app distro
# Run function
iex(abc@my-machine)1> Distro.DistroCal.add(4,5)
9
```


## Multiple nodes

### Start all 3 nodes

You could use __Tmux__ for this ;o)

_Terminal 1_

`$ iex --name one@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/one"`

_Terminal 2_

`$ iex --name two@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/two"`

_Terminal 3_

`$ iex --name three@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/three"`


## Play with take over

Shut down(ctrl-c) node _one_ and see the GenServer start on node _two_ or _three_

In the example below it's node `three@127.0.0.1` taking over

Example output, node `three@127.0.0.1` terminal
```
15:57:28.955 [info]  Distro application in :normal mode
15:57:28.955 [info]  Starting server
```

Execute the function `Distro.DistroCal.add(4,5)` on both running nodes, observe see what happens


Start node `one@127.0.0.1` again

Example output, node `one@127.0.0.1` terminal
```
$ iex --name one@127.0.0.1 -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/one"
15:58:07.132 [info]  Distro application in {:takeover, :"three@127.0.0.1"} mode
15:58:07.133 [info]  Starting server
```

Example output, node `three@127.0.0.1` terminal
```
15:58:07.134 [info]  Application distro exited: :stopped
```

Run `Distro.DistroCal.add(4,5)` again


## Client on a separate machine


### Cookie

Previously running on the same machine, we could rely on the nodes sharing the cookie situated in the folder
`~/.erlang.cookie`. This is however not the case when running nodes on different machines. In this example, we apply the cookie as a command line argument using `--cookie <COOKIE>`.

The cookie value in the example is `cookie`, but should probably be something else in production. The nodes should, for security reason, never be acessible from outside(e.g. internet).

### Machine name

We must furthermore use an ip-address(or machine name), with which the nodes can connect to each other, here 192.168.0.29.

Example of updated config, with new ip address

```
[{kernel,
  [{distributed, [{'distro', 5000, ['one@192.168.0.29', {'two@192.168.0.29', 'three@192.168.0.29'}]}]},
   {sync_nodes_mandatory, ['one@192.168.0.29', 'two@192.168.0.29']},
   {sync_nodes_timeout, 30000}
]}].
```

### Start the nodes

_Terminal 1_

```
$ iex --name one@192.168.0.29 --cookie cookie -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/one"
```

_Terminal 2_

```
$ iex --name two@192.168.0.29 --cookie cookie -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/two"
```

_Terminal 3_

```
$ iex --name three@192.168.0.29 --cookie cookie -pa _build/dev/lib/distro/ebin/ --app distro --erl "-config config/three"
```

_Client_

Start the client.
Ping one of the nodes, and we are automatically connected to the others as well

```
$ iex --name client@192.168.0.12 --cookie cookie
iex(client@192.168.0.12)1> Node.ping :"one@192.168.0.29"
:pong
iex(client@192.168.0.12)2> Node.list
[:"one@192.168.0.29", :"three@192.168.0.29", :"two@192.168.0.29"]
iex(client@192.168.0.12)3> GenServer.call({:global, Distro.DistroCal}, {:cal, 2, 1})
3
```
