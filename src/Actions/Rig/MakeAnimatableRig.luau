local m = {}

local inst_root = script.Parent.Parent.Parent
local inst_morph = inst_root.TprrMorphLib.OldTprrMorph

local MorphUtils = require(script.Parent.MorphUtils)

local Morph = require(inst_morph)
local Result = require(inst_root.Result)


function m.MakeRig(model: Model): Result.Result<Model, string>

	local humanoidRootPartModel = model:FindFirstChild("HumanoidRootPart")
	if not (humanoidRootPartModel and humanoidRootPartModel:IsA("Model")) then
		return Result.Err("The provided model is not a valid TPRR rig.")
	end
	
	if not (model:FindFirstChild("HumanoidRootPart") and humanoidRootPartModel.PrimaryPart) then
		return Result.Err("No root part.")
	end
	
	local function Recurse(parent)
		for _, model in pairs(parent:GetChildren()) do
			if model:IsA("Model") then
				if not model.PrimaryPart then
					return Result.Err(
						model.Name .. " has no primary part."
					)
				elseif MorphUtils.JointPartIndex[model.PrimaryPart.Name] ~= model.Name then
					return Result.Err(
						model.Name .. "\'s primary part is not named or set properly."
					)
				end
			end
		end
		return true
	end
	
	Recurse(model)
	
	local baseCharacter = inst_morph.PlayerRigData.Dummy:Clone()
	local hum = baseCharacter:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildWhichIsA("Animator")
	if hum and not animator then
		Instance.new("Animator", hum)
	end

	local newModel = model:Clone()
	
	baseCharacter.Parent = newModel.Parent
	baseCharacter:PivotTo(
		newModel.HumanoidRootPart.PrimaryPart.CFrame
	)
	
	Morph:MorphRig(baseCharacter, newModel, {UseManualWelds = true})
	
	for _, v in pairs(baseCharacter:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.Anchored = false
		end
	end

	newModel:Destroy()
	
	return Result.Ok(baseCharacter)
end


return m
