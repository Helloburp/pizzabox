local m = {}


local utilities = require(script.Parent.MorphUtils)
local morph = require(script.Parent.OldTprrMorph)
local Result = require(script.Parent.Parent.Result)


function m.MakeRig(model: Model): Result.Result<Model, string>

	local humanoidRootPartModel = model:FindFirstChild("HumanoidRootPart")
	if not (humanoidRootPartModel and humanoidRootPartModel:IsA("Model")) then
		return Result.FromE("The provided model is not a valid TPRR rig.")
	end
	
	if not (model:FindFirstChild("HumanoidRootPart") and humanoidRootPartModel.PrimaryPart) then
		return Result.FromE("No root part.")
	end
	
	local function Recurse(parent)
		for _, model in pairs(parent:GetChildren()) do
			if model:IsA("Model") then
				if not model.PrimaryPart then
					return Result.FromE(
						model.Name .. " has no primary part."
					)
				elseif utilities.JointPartIndex[model.PrimaryPart.Name] ~= model.Name then
					return Result.FromE(
						model.Name .. "\'s primary part is not named or set properly."
					)
				end
			end
		end
		return true
	end
	
	Recurse(model)
	
	local baseCharacter = script.Parent.OldTprrMorph.PlayerRigData.Dummy:Clone()

	local newModel = model:Clone()
	newModel.Parent = model.Parent
	newModel:PivotTo(newModel:GetPivot() * CFrame.new(0, 5, 0))
	
	baseCharacter.Parent = newModel.Parent
	baseCharacter:SetPrimaryPartCFrame(
		newModel.HumanoidRootPart.PrimaryPart.CFrame
	)
	
	morph:MorphRig(baseCharacter, newModel, {UseManualWelds = true})
	
	for _, v in pairs(baseCharacter:GetChildren()) do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			v.Anchored = false
		end
	end

	newModel:Destroy()
	
	return Result.FromT(baseCharacter)
end


return m
