--!nocheck

--[[
	CheapNet is a networking library designed for running networking code at a
	low performance cost while having the capabilities to be incredibly safe,
	encouraging the user to leverage typechecking and more.
	
	-- @ Documentation
	We'll provide basic-level documentation right here, keeping the code from
	being filled with unnecessary bloat that is irrelevant.
	
	-- Functions
	CheapNet.new(name: string, check: <T...>(T...) -> (boolean, ...any))
		Opens a new RemoteEvent that can be used by the developer to transmit
		signals from the server to the client and vice-versa.
		
		Check is used to cast a type and make sure that whatever the remote received
		is valid. This is useful to prevent unwanted exploiters from sending
		invalid data to the server.
		
		
		
]]

local RunService = game:GetService("RunService")

local Serializer = require(script.Serializer)
local PacketFilterable = require(script.PacketFilterable)
local sharedState = require(script.sharedState)

export type PacketFilterable = PacketFilterable.PacketFilterable
type Middleware = (player: Player, ...any) -> ...any
type Connection = {Disconnect: (Connection)}
type Signal<T...> = sharedState.Signal<T...>

export type UnifiedBridge<C..., S...> = {
	
	Id: number,
	
	FireToClients: (UnifiedBridge<C..., S...>, C...) -> PacketFilterable,
	FireAllClients: (UnifiedBridge<C..., S...>, C...) -> PacketFilterable,
	FireServer: (UnifiedBridge<C..., S...>, S...) -> (),
	
	SetInboundMiddleware: (UnifiedBridge<C..., S...>, {Middleware}) -> (),
	SetOutboundMiddleware: (UnifiedBridge<C..., S...>, {Middleware}) -> (),
	
	-- Signal
	OnServerReceive: Signal<(Player, S...)>,
	OnClientReceive: Signal<(C...)>,
	
	eachC: (UnifiedBridge<C..., S...>) -> () -> (C...),
	eachS: (UnifiedBridge<C..., S...>) -> () -> (Player, S...),
	
}

local CheapNet = {}

function CheapNet.new<S..., C...>(bridge: string, server_test: ((S...) -> (boolean, string?))?, client_test: ((C...) -> (boolean, string?))?): UnifiedBridge<C..., S...>
	
	if RunService:IsServer() then
		local ServerBridge = require(script.ServerBridge)
		return ServerBridge.new(bridge, server_test)
	else
		local ClientBridge = require(script.ClientBridge)
		return ClientBridge.new(bridge, client_test)
		
	end
	
end

local frame = 0
local initial_frame = 0
RunService.Heartbeat:Connect(function(delta_time)
	
	frame += 1
	
	-- Clear up all the existing packets
	if RunService:IsServer() then
		debug.profilebegin("CheapNet Server")
		Serializer.onSendServer()
	else
		debug.profilebegin("CheapNet Client")
		Serializer.onSendClient()
	end
	debug.profileend()
end)

if RunService:IsClient() then
	script.Remote.OnClientEvent:Connect(function(...)
		
		debug.profilebegin("CheapNet Client")
		if frame ~= initial_frame then
			for _, bridge in sharedState.bridges do
				bridge._packets = {}
			end
			initial_frame = frame
		end
		
		local start = os.clock()
		local total = Serializer.onReceiveClient(...)
		local finish = os.clock()
		
		debug.profileend()
		
		print(math.floor((finish - start) * 10000000) / 10, "μs", "processed", total)
	end)
else
	
	script.Remote.OnServerEvent:Connect(function(...)
		debug.profilebegin("CheapNet Server")
		if frame ~= initial_frame then
			for _, bridge in sharedState.bridges do
				bridge._packets = {}
			end
			initial_frame = frame
		end
		
		Serializer.onReceiveServer(...)
		debug.profileend()
	end)
end

return CheapNet