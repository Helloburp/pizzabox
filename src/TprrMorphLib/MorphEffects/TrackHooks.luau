
local m = {}

function m.HookTrack(
	animationTrack: AnimationTrack,
	handlers: {[string]: ((number) -> () | (string) -> ())}
): {RBXScriptConnection}
	local connections = {}
	for eventName, _handle in pairs(handlers) do
		table.insert(connections, animationTrack:GetMarkerReachedSignal(eventName):Connect(_handle))
	end

	return connections
end

return m