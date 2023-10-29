# Signal

A lua signal that cannot yield

## Methods

### connect()

Connects a callback to the signal

-   **Type**

```lua
function Signal<T...>:connect(callback: (T...) -> ()): Connection
```

-   **Details**

Each callback can only be ever connected once until disconnected.
If you connect the exact same function more than once, it will be ignored.

Callbacks may not yield, yielding inside a signal will delay the execution of
other packets being received. Please make sure to create a new thread if you
are planning to yield.

---

### wait()

Waits until the signal is fired.

-   **Type**

```lua
function Signal<T...>:wait(): T...
```

---

### once()

Connects a callback once and disconnects after.

-   **Type**

```lua
function Signal<T...>:once(callback: (T...) -> ()): Connection
```
