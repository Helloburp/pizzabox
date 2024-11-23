local CameraShaker = require(script.Parent.CameraShaker)

local inst_marker_handlers = script.MarkerHandlers

local MarkerHandlers = require(inst_marker_handlers)
local Shake = require(inst_marker_handlers.Shake)
export type DoShake = Shake.DoShake

local TrackHooks = require(script.TrackHooks)

local m = {}


export type MorphEffectsController = {
	Update: () -> (),
	Cleanup: () -> ()
}


function m.NewDefaultCameraShaker(shakeOnlyOnCustomCameraType: boolean?): DoShake
	local shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		game.Workspace.Camera.CFrame *= shakeCFrame
	end)

	shaker:Start()

	return function(...)
		if (
			shakeOnlyOnCustomCameraType
			and game.Workspace.Camera.CameraType ~= Enum.CameraType.Custom
		) then return end

		shaker:ShakeOnce(...)
	end
end


function m.NewMorphEffectsController(
	rootModel: Model,
	root: BasePart,
	animator: Animator,
	soundLibrary: Instance,
	_shake: DoShake,
	soundParentOverride: Instance?
): MorphEffectsController
	local markerHandlers = MarkerHandlers.NewMarkerHandlers(
		soundLibrary,
		rootModel,
		root,
		_shake,
		soundParentOverride
	)
	local trackHooks = {}
	return {
		Update = function()
			trackHooks = TrackHooks.UpdateTrackHooks(animator, markerHandlers, trackHooks)
		end,
		Cleanup = function()
			trackHooks = TrackHooks.CleanupTrackHooks(trackHooks)
		end
	}
end

return m
