# 0.4.3

## Fixes
- Fixed a memory leak

# 0.4.2

## Added
- Added `CheapNet.pack` and `CheapNet.unpack`
- Exported types for `LeakyBucket`

## Improvements
- Improved reliability of `:eachC` and `:eachS`
	> Note: Calls are required as otherwise, you'll produce a memory leak since
	> the packets will not be cleared. Packets are only cleared every `:each`
	> call and will iterate over the packets that have been sent between `:each`
	> calls. This stops potentially missing packets.

# 0.4.0

## Added
- Added Leaky Buckets
- Added before and after runtime typecheck tests
	> Tests run on both server and client including when you fire.
	> These runtime typecheck tests now prevent both developer error and
	> exploiters sending bad packets.
## Improvements
- Improved Types
- Improved Middleware Error Messaging
- Middleware is now safely called.
	> When middleware fails, packets are dropped. Yielding may cause unexpected
	> behavior.
	
# 0.3.3

## Improvements
- Implemented Efficient Integer Packing
	> Integers are now packed as efficiently as possible.
	> Bridges and Identifiers now support more than 65536 Ids.

# 0.3.2

## Fixes
- Fixed a bug with identifiers

# 0.3.1

## Fixes
- Fixed a bug with multiple identifiers

# 0.3

## Added
- Added Identifiers
- Added `Bridge:GetLocalIdentifier` and `Bridge:FromLocalIdentifier`
- Added `CheapNet:GetGlobalIdentifier` and `CheapNet:FromGlobalIdentifier`

# 0.2

## Added
- Added `ClientBridge:eachC` and `ServerBridge:eachS`
	> This method will iterate through the current frame's packets.
	> This is useful inside ECS frameworks where they run code every frame.

## Improvements
- Deserialization is now faster when there are no connections to the Signal
	> This is because when a Signal runs, they'll have to create threads to
	> run the connected callbacks which is expensive.
	> Using the `:eachC` and `:eachS` functions, you can iterate through the
	> packets instead.

## Removed
- Removed hidden `UnifiedBridge:each()` method

# 0.1
- Initial Release