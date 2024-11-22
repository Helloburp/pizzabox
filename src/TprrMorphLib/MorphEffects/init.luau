local CameraShaker = require(script.Parent.CameraShaker)

local inst_marker_handlers = script.MarkerHandlers

local MarkerHandlers = require(inst_marker_handlers)
local Shake = require(inst_marker_handlers.Shake)
export type DoShake = Shake.DoShake

local m = {}


function m.NewDefaultCameraShaker(): DoShake
	local shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
		game.Workspace.Camera.CFrame *= shakeCFrame
	end)

	shaker:Start()

	return function(...)
		shaker:ShakeOnce(...)
	end
end


function m:New(animator)
	local o = {}
	
	assert(typeof(animator) == "Instance")
	assert(animator:IsA("Animator"))
	
	o.ActiveDist = 100
	o.Humanoid = nil
	o.RootPart = nil
	
	o.Active = false
    o.Destroyed = false
	
	if animator.Parent and animator.Parent:IsA("Humanoid") then
		o.Humanoid = animator.Parent
		if o.Humanoid.Parent:FindFirstChild("HumanoidRootPart") then
			o.RootPart = o.Humanoid.Parent.HumanoidRootPart
		end
	end
	
	function o:GetRootPart()
		if o.Humanoid.Parent and o.Humanoid.Parent:FindFirstChild("HumanoidRootPart") then
			o.RootPart = o.Humanoid.Parent.HumanoidRootPart
			return o.Humanoid.Parent.HumanoidRootPart
		end

        return nil
	end
	
	assert(typeof(o.Humanoid) == "Instance" and o.Humanoid:IsA("Humanoid"))
	
	local currentSignals = {}
	local newAnimSignal = nil
	
	local unIndexAnimations = function()
		for track, signalList in pairs(currentSignals) do
			for signal, _ in pairs(signalList) do
				signal:Disconnect()
				signalList[signal] = nil
			end
		end
		
		currentSignals = {}
		
		if newAnimSignal then
			newAnimSignal:Disconnect()
			newAnimSignal = nil
		end
	end
	
	local indexTrack = function(newTrack)
		assert(typeof(newTrack) == "Instance" and newTrack:IsA("AnimationTrack"))
		if newTrack.Name == "walk" then
			return
		end
		
		local mySignalList = {}
		
		for eventName, method in pairs(markerMethods.MarkerMethods) do
			local connection = newTrack:GetMarkerReachedSignal(eventName):Connect(function(value)
				if o:GetRootPart() then
					method(o, value)
				end
			end)
			
			mySignalList[connection] = true
		end
		
		currentSignals[newTrack] = mySignalList
	end
	
	local steppedConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		if not o:GetRootPart() then return end
		local inRange = false
		local dist = (game.Workspace.Camera.CFrame.Position - o:GetRootPart().Position).Magnitude
		if dist < o.ActiveDist then
			inRange = true
		end
		
		if not o.Active and inRange then
			for _, track in pairs(animator:GetPlayingAnimationTracks()) do
				indexTrack(track)
			end
			
			local playSignal = animator.AnimationPlayed:Connect(function(newTrack)
				indexTrack(newTrack)
			end)
			
			newAnimSignal = playSignal
			
		elseif o.Active and not inRange then
			unIndexAnimations()
		end
		
		o.Active = inRange
	end)
	
	function o:Destroy()
		if not o.Destroyed then
			o.Destroyed = true
			unIndexAnimations()
			steppedConnection:Disconnect()
		end
	end
	
	return o
end

return m
