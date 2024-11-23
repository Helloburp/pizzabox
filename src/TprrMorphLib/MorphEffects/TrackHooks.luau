
local m = {}

function m.HookTrack(
	animationTrack: AnimationTrack,
	handlers: {[string]: (string) -> ()}
): {RBXScriptConnection}
	local connections = {}
	for eventName, _handle in pairs(handlers) do
		table.insert(connections, animationTrack:GetMarkerReachedSignal(eventName):Connect(_handle))
	end

	return connections
end


function m.UpdateTrackHooks(
	animator: Animator,
	handlers: {[string]: (string) -> ()},
	trackHooks: {[AnimationTrack]: {RBXScriptConnection}}
): {[AnimationTrack]: {RBXScriptConnection}}
	local tracks = animator:GetPlayingAnimationTracks()

	for track, hooks in trackHooks do
		if table.find(tracks, track) then continue end
		_cleanupTrack(trackHooks, track)
	end

	for _, track in tracks do
		trackHooks[track] = trackHooks[track] or m.HookTrack(track, handlers)
	end

	return trackHooks
end


function m.CleanupTrackHooks(
	trackHooks: {[AnimationTrack]: {RBXScriptConnection}}
): {[AnimationTrack]: {RBXScriptConnection}}
	for track, hooks in trackHooks do
		_cleanupTrack(trackHooks, track)
	end
	return trackHooks
end


function _cleanupTrack(trackHooks: {[AnimationTrack]: {RBXScriptConnection}}, track: AnimationTrack)
	for _, connection in trackHooks[track] do
		connection:Disconnect()
	end
	trackHooks[track] = nil
end


return m