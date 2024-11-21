local adAssets = require(
	script.Parent.Parent:WaitForChild("AnimatronicData")
).Getters

local soundPlayer = require(script.SoundPlayer):New(
	adAssets.AnimationSoundsFolder()
)
local camShaker = require(script.CameraShaker).new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
	game.Workspace.Camera.CFrame *= shakeCFrame
end)

local emitter = require(script.ParticleEmitter)

camShaker:Start()

local module = {}

-- For methods in this list, self is implied to be the anim controller.

module.MarkerMethods = {}

local soundCooldowns = {}

function module.MarkerMethods:Sound(value)
	local curPart = self:GetRootPart()
	
	if not game.Workspace:IsAncestorOf(curPart) then return end
	
	if not soundCooldowns[value] then
		
		soundCooldowns[value] = curPart
		spawn(function()
			soundPlayer:PlaySound(value, curPart)
			wait(0.05)
			soundCooldowns[value] = nil
		end)
	end
end

local lastShake = false

function module.MarkerMethods:Shake(value)
	value = math.min(value, 3)
	local canShake = not (_G.__PLR_IN_MINIGAME or _G.__EDITING_ENABLED or lastShake)
	
	if not canShake then return end
	
	if not game.Workspace:IsAncestorOf(self:GetRootPart()) then return end
	
	local dist = (game.Workspace.Camera.CFrame.Position - self:GetRootPart().Position).Magnitude
	local max = tonumber(value)
	if dist < max then
		if game.Workspace.Camera.CameraType ~= Enum.CameraType.Custom then return end
		local magnitude = (max - dist) * value/6
		camShaker:ShakeOnce(magnitude, magnitude, 0.1, 0.1, Vector3.new(0.05, 0.05, 0.05), Vector3.new(0.1, 0.1, 0.1))
	end
	
	lastShake = true
	game:GetService("RunService").RenderStepped:Wait()
	lastShake = false
end

function module.MarkerMethods:Emit(value)
	local curPart = self:GetRootPart()
	if not curPart.Parent then return end
	
	local model = curPart.Parent
	if not game.Workspace:IsAncestorOf(model) then return end
	emitter:Emit(model, value)
end

function module.MarkerMethods:Show(value)
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

function module.MarkerMethods:Hide(value)
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

return module
