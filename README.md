# CheapNet

CheapNet is a lazy alternative to BridgeNet which is semi-actively maintained?
It should be pretty similar qua api and easy to understand as it comes with Luau types.

## Setting Up

Install CheapNet through Wally using `wally.toml` by adding `CheapNet = aloroid/cheapnet@0.1.0`

You should probably create a file inside a shared space that both server and clients can access which creates the bridges that need to be accessed.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages

local CheapNet = require(Packages.CheapNet)

return {
	
	remote_1 = CheapNet.new("remote/1"),
	remote_2 = CheapNet.new("remote/2")
	
}
```

You can even add in a runtime typechecking test using the second argument which will check the types that are given to a remote, which can be handy to preventing exploiters.

Please note that the typechecking test runs after the middleware, as I really just made it like this to get types on the remotes and stuff that I write.

You can do it like this:

```lua
return {
	
	remote_1 = CheapNet.new("remote/1", function(value: string)
		return type(value) == "string"
	end), -- This will now fail if the value passed into it is not a string.
	remote_2 = CheapNet.new("remote/2")
	
}
```

It's recommended to install a library like [`t`](https://github.com/roblox/t) to do this for you so it won't look as cluttered.
(You should use my fork of [`t`](https://github.com/aloroid/t) which comes with some nice Luau typechecking)

## Basic Usage
CheapNet is pretty easy to use and doesn't have a big API.

Documentation is non-existent because I am lazy.<br>
Instead, have a example!
```lua
-- Shared
local Bridge = CheapNet.new("luanoid_shoot", t.CFrame)

-- Client
Bridge.OnClientEvent:Connect(function(cframe: CFrame)
	print("he pew at", cframe.Position)
end)

-- Server
Bridge:FireToClients(cframe):include(initialized_players):exclude(owner)

```
 
---

## Why create another networking library?
.
## Why should I use this over BridgeNet?

Other than the fact that this uses less bandwidth by using a very nice and better system to pack remote calls, no idea! BridgeNet offers identifiers which CheapNet doesn't have, so I just made this out of selfish reasons and boredom.

## Why did you name it CheapNet?
It's made cheaply. It's a little bit slower than BridgeNet because of the superior bandwidth usage but other than that it should be fine.
