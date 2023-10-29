# CheapNet

## Functions

### create_identifier()

Creates a unique identifier for a given value. This can be sent over network
and then be decoded to get the actual value.

-   **Type**

```lua
function cheapnet.create_identifier(value: any, namespace: string?): string
```

-   **Details**

Identifiers will not be destroyed after creation and any value you pass in will
never be garbage collected. Make sure any tables you pass in are immutable, as
they will not replicate any changes.

When called on the client, the client will yield indefinitely until the
identifier exists on the client.

---

### get_value()

Gets the value associated with a identifier.

-   **Type**

```lua
function cheapnet.get_value(identifier: string, namespace: string?)
```

-   **Details**

Returns nil if it's a unknown identifier.

---

### event()

Creates a new [Event](event) that can be used to transmit data to the client.

-   **Type**

```lua
function cheapnet.event(key: any, type: "ordered" | "unordered" | "unreliable" | "unreliable_drop_old_packets"?, (typechecker: (T...) -> boolean)?): Event<T...>
```

-   **Details**

There is a max limit of 65536 events. A deoptimization will happen where all
packet identifiers get widened when you have more than 256 events.

---

### pack()

Packs a integer or unsigned integer into a small string.

-   **Type**

```lua
function cheapnet.pack(int: number, unsigned: boolean?): string
```

---

### unpack()

Unpacks a string back into a integer.

-   **Type**

```lua
function cheapnet.unpack(int: string, unsigned: boolean?): number
```

---

### leaky_bucket()

Creates a new [leaky bucket](leaky_bucket) which can be used to rate-limit players.

-   **Type**

```lua
function cheapnet.leaky_bucket(drain: number, max: number): LeakyBucket
```

---

### get_timestamp()

Gets the timestamp currently. This only works when called inside a callback
connected to a [Event](event).
This lets you get the time when the player or server sent the current packet.

-   **Type**

```lua
function cheapnet.get_timestamp(): number
```

-   **Details**

Returns 0 when called outside a event.

## Events

### player_warning

This event is fired whenever a player has triggered some limit in cheapnet.
Currently, this is fired when the player:

-   `TOO_MANY_EVENTS` A player has sent to or more than 10000 remotes
-   `TOO_MANY_PACKETS` A player has sent more than 10000 packets (ordered and unordered)
-   `INVALID_TIMESTAMP` A player has sent a invalid timestamp.

The developer may choose how to deal with the player when they surpass this limit.

-   **Type**

```lua
cheapnet.player_warning: Signal<Player, "TOO_MANY_EVENTS" | "TOO_MANY_PACKETS" | "INVALID_TIMESTAMP">
```
