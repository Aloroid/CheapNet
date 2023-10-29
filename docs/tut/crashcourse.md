# Crash Course

CheapNet is a fast modern networking library written in a really short time.

## Events

CheapNet's primary way of communicating to the server is using events.
You can imagine events as wrapping around a RemoteEvent in Roblox.

When creating a event, you must provide a key. Events can be in 4 modes,
`ordered`, `unordered`, `unreliable` and `unreliabe_drop_old_packets`.
The mode can only be provided when initially creating the event as the second
argument. When omitted, the default mode will be unordered.

```lua
CheapNet.event("request_purchase", "ordered")
CheapNet.event("replicate_head_location", "unreliable_drop_old_packets")
```

In order to send a packet to a client/server, call `:fire_client` or `:fire_server`.
When calling `:fire_server`, you will receive a special filterable object that
lets you easily choose who to fire to and who to ignore.

```lua
request_purchase:fire_server("magic_rod")

replicate_positions:fire_clients(id, Vector3.new(0, 0, 0)):all():exclude(player)
```

## Identifiers

Identifiers lets you store complex data as a small identifier to avoid
resending large data structures that are the same.
Identifiers can only be created on the server.

```lua
local identifier = CheapNet.create_identifier(51, "numbers") -- gets the id
local value = CheapNet.get_value(identifier, "numbers") -- gets the value
```
