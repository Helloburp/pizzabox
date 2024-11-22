
local m = {}

-- For methods in this list, self is implied to be the anim controller.

local Sound = require(script.Sound)
local Shake = require(script.Shake)
type DoShake = Shake.DoShake


function m.NewMarkerHandlers(
	soundLibrary: Instance,
	character: Model,
	root: PVInstance,
	_shake: DoShake
): {[string]: (any) -> ()}
	return {
		Sound = function(name: any)
			assert(
				typeof(name) == "string",
				"Animation Marker named 'Sound' must have a value of type String."
			)
			Sound.PlayThenDestroyFromLibrary(name, soundLibrary, root)
		end,

		Shake = function(intensity: any)
			assert(
				typeof(intensity) == "number",
				"Animation Marker named 'Shake' must have a value of type Number."
			)
			Shake.CameraShake(intensity, root:GetPivot().Position, _shake)
		end,

		Emit = function(id: any)
			assert(
				typeof(id) == "string",
				"Animation Marker named 'Emit' must have a value of type String."
			)
			for _, instance in pairs(character:GetDescendants()) do
				if not (instance:IsA("ParticleEmitter") and instance.Name == id) then continue end
				instance:Emit(instance:GetAttribute("EMIT_AMOUNT") or instance.Rate)
			end
		end,

		Show = function(name: any)
			assert(
				typeof(name) == "string",
				"Animation Marker named 'Show' must have a value of type String."
			)
			_changeTransparencyOfPartsWithName(character, name, -1)
		end,

		Hide = function(name: any)
			assert(
				typeof(name) == "string",
				"Animation Marker named 'Hide' must have a value of type String."
			)
			_changeTransparencyOfPartsWithName(character, name, 1)
		end
	}
end


function _changeTransparencyOfPartsWithName(character: Model, name: string, deltaTransparency: number)
	for i, instance in character:GetDescendants() do
		if not (instance.Name == name and instance:IsA("BasePart")) then continue end
		instance.Transparency += deltaTransparency
	end
end


m.MarkerMethods = {}

local soundCooldowns = {}

function m.MarkerMethods:Sound(value)
	local curPart = self:GetRootPart()
	
	if not game.Workspace:IsAncestorOf(curPart) then return end
	
	if not soundCooldowns[value] then
		
		soundCooldowns[value] = curPart
		spawn(function()
			wait(0.05)
			soundCooldowns[value] = nil
		end)
	end
end

local lastShake = false


function m.MarkerMethods:Shake(value)
	value = math.min(value, 3)
	local canShake = not (_G.__PLR_IN_MINIGAME or _G.__EDITING_ENABLED or lastShake)
	
	if not canShake then return end
	
	if not game.Workspace:IsAncestorOf(self:GetRootPart()) then return end
	
	local dist = (game.Workspace.Camera.CFrame.Position - self:GetRootPart().Position).Magnitude
	local max = tonumber(value)
	if dist < max then
		if game.Workspace.Camera.CameraType ~= Enum.CameraType.Custom then return end
	end
	
	lastShake = true
	game:GetService("RunService").RenderStepped:Wait()
	lastShake = false
end

function m.MarkerMethods:Emit(value)
	local curPart = self:GetRootPart()
	if not curPart.Parent then return end
	
	local model = curPart.Parent
	if not game.Workspace:IsAncestorOf(model) then return end
end

function m.MarkerMethods:Show(value)
	local curPart = self:GetRootPart()
	if not curPart.Parent then return end

	local model = curPart.Parent
	if not game.Workspace:IsAncestorOf(model) then return end
	
	for i, v in model:GetDescendants() do
		if v.Name == value and v:IsA("BasePart") then
			
			if v.Transparency >= 1 then
				v.Transparency -= 1
			end
		end
	end
end

function m.MarkerMethods:Hide(value)
	local curPart = self:GetRootPart()
	if not curPart.Parent then return end

	local model = curPart.Parent
	if not game.Workspace:IsAncestorOf(model) then return end

	for i, v in model:GetDescendants() do
		if v.Name == value and v:IsA("BasePart") then

			if v.Transparency < 1 then
				v.Transparency += 1
			end
		end
	end
end

return m
