# event

RemoteEvent wrapper

## Properties

### id

The special identifier used to identify the event internally

-   **Type**

`number`

---

### behavior

Contains how the event should behave when receiving a packet.

-   **Type**

`"ordered" | "unordered" | "unreliable" | "unreliable_drop_old_packets"`

## Methods

### fire_server

Sends a packet to the server with the given arguments

-   **Type**

```lua
function event:fire_server(...: any)
```

---

### fire_clients

Sends a packet to the given clients with the given arguments and returns a [filterable](filterable).

-   **Type**

```lua
function event:fire_clients(...: any): Filterable
```

-   **Example**

```lua
is_sherrif:fire_clients(player):all():exclude(murderer)
```

## Events

### on_client_event

This event is fired whenever the client receives a packet.

-   **Type**

```lua
Signal<...any>
```

---

### on_server_event

This event is fired whenever the server receives a packet from the client

-   **Type**

```lua
Signal<Player, ...any>
```
