# Distributing Aya

## Should I distribute Aya?
### Drawbacks
* Substantially increased latency per request
* Erlang distribution is NOT built for security
* Will not function perfectly in the event of a netsplit/partition

### Advantages
* Ability to horizontally scale as necessary
* Greater resilience in the event of a node failing

If you do want to run Aya in a distributed manner, you should think carefully and do analysis and benchmarking.
Distribution will work best when the latency Aya experiences under load is greater than the network latency that results
from distributing it. Due to erlang's poor node security, distribution is best done on a local cluster, and
a strong cookie should be chosen for usage. SSL may be included later in Aya for additional security.

## Setup
Currently support for distributing Aya is untested, and just beginning to be implemented.
These instructions are all subject to change as a result.

1. Setup config.exs to support distribution. A total distributed weight should be given, and a list of node names.
Each node should be given in the form `{node_name, range}`. The range will determine the weighted change of a node
being used for a certain torrent. For example, if two nodes were used and each were equally powerful,
the distributed node list would look like `[{`foo@host1`, 1..1}, {bar@host2, 2..2}]` with the distribution weight set to 2
2. Build a release, and modify the rel/aya/running-config/vm.args file to have the proper hostname
3. In theory this is all that will be necessary. Aya's internal routing mechanism will distribute the torrent genservers
across your nodes and thus keep load fairly balanced.
