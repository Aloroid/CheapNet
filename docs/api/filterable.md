# Filterable

A filterable is a class that you can use to easily select the players you want
to send a packet to.
This is returned by `event:fire_clients`

## Methods

### include()

Includes a array of players

-   **Type**

```lua
function filterable:include(players: {Player} | Player): filterable
```

---

### exclude()

Excludes a array of players

-   **Type**

```lua
function filterable:exclude(players: {Player} | Player): filterable
```

---

### all()

Includes all players

-   **Type**

```lua
function filterable:all(): filterable
```

---

### never()

:never excludes a player in a filterable.

This will remove the player from the filterable and make sure it can't be
added again. Calling this on a player that must always be included in will error.
Subsequent :include and :all calls will ignore this player

-   **Type**

```lua
function filterable:never(players: {Player} | Player): filterable
```

---

### always()

:always includes a player in a filterable.

This will include the player from the filterable and make sure it can't be
removed again.
Calling this on a player that must never be included in will error.
Subsequent :exclude calls will ignore this player.

-   **Type**

```lua
function filterable:always(players: {Player} | Player): filterable
```

---

### list()

Returns a list of all the players who must be included

-   **Type**

```lua
function filterable:list(): {Player}
```

---

### has()

Returns if the player is included in the filterable

-   **Type**

```lua
function filterable:has(player: Player): boolean
```
