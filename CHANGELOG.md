# Unreleased

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