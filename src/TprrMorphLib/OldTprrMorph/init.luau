--[[
	Special system quirks
	
	The primary part is parented to the character.
	It acts as an extension of the R15 system and is a part along with everything else.
	
	The model is renamed to the name of the joint.
]]


local plrRigData = require(script.PlayerRigData)
local specialModule = script:FindFirstChild("SpecialBehavior")
if specialModule then
	specialModule = require(specialModule :: ModuleScript)
end

local morphHelper = require(script.MorphHelper)

local module = {}

local setupPart = function(part)
	part.Anchored = false
	part.CanCollide = false
	part.Massless = true
	part.CanTouch = false
end

local validPartNames = morphHelper.ValidPartNames

function module:GetPartFromCharacter(char, name)
	for _, child in pairs(char:GetChildren()) do
		if child:IsA("BasePart") and child.Name == name then
			return child
		end
	end
end

function module:RemoveOldPart(char, partName)
	for _, model in pairs(char:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("__MorphModel") == partName then
			model:Destroy()
		end
	end
end

function module:ClearMorph(char)
	for _, model in pairs(char:GetChildren()) do
		if model:IsA("Model") and model:GetAttribute("__MorphModel") then
			model:Destroy()
		elseif model:IsA("BasePart") and model:GetAttribute("__MorphRoot") then
			model:Destroy()
		end
	end
end

local function IsModelExtraLimb(model)
	return (model.Name ~= "Faceplates" and model.Name ~= "Plate")
end

-- Takes a rig and generates a single model clone without rig children.
function module:IsolateModel(rig, partName)

	if not rig then return end

	for _, model in pairs(rig:GetDescendants()) do
		if model:IsA("Model") and model.Name == partName then
			local subClone = model:Clone()
			for _, child in pairs(subClone:GetChildren()) do
				if child:IsA("Model") and (validPartNames[child.Name] or (child.PrimaryPart and IsModelExtraLimb(child))) then
					child:Destroy()
				end
			end

			return subClone
		end
	end
end

function module:MorphPart(part, model, meta)
	meta = meta or {}
	local visibleRoot = meta.RootIsVisible or false
	local useManualWelds = meta.UseManualWelds or false

	model:SetAttribute("__MorphModel", part.Name)
	local centralPart = model.PrimaryPart or model:FindFirstChildOfClass("Part")
	local isCorePart = centralPart ~= part
	if not model.PrimaryPart then model.PrimaryPart = centralPart end

	assert(centralPart, string.format("Model %s has no primary part!", model.Name))

	local weldMethod = function() end

	local weldList = {}

	if useManualWelds then
		weldMethod = function(child)
			local weld = Instance.new("Weld", child)
			weld.Enabled = not isCorePart
			weld.Part0 = centralPart
			weld.Part1 = child

			weld.C1 = child.CFrame:Inverse() * centralPart.CFrame

			table.insert(weldList, weld)
		end
	else
		weldMethod = function(child)
			local weld = Instance.new("WeldConstraint", child)
			weld.Part0 = centralPart
			weld.Part1 = child
		end
	end

	local function WeldParts(parent)
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("BasePart") and child ~= centralPart then
				weldMethod(child)
			elseif child:IsA("Model") then
				if not child:GetAttribute("WeldOverride") then
					WeldParts(child)
				end
			elseif child:IsA("Folder") then
				WeldParts(child)
			end
		end
	end

	if specialModule then specialModule:PreWeld(part.Parent, model) end

	WeldParts(model)

	local weld = Instance.new("Weld", centralPart)
	weld.Part0 = centralPart
	weld.Part1 = part


	local rigOffset = CFrame.new()

	if part:FindFirstChild("MorphOffset") then
		rigOffset = part.MorphOffset.Value
		if rigOffset then weld.C1 = rigOffset end
	end

	if not visibleRoot then model.PrimaryPart.Transparency = 1 end
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then setupPart(part) end
	end

	if specialModule then specialModule:PostWeld(part.Parent, model) end
	if model.Name == "HumanoidRootPart" then model.Name = "_HumanoidRootPart" end

	if useManualWelds and isCorePart then
		if isCorePart then
			for _, otherWeld in pairs(weldList) do
				otherWeld.Part0 = part
				otherWeld.C1 = otherWeld.Part1.CFrame:Inverse() * part.CFrame
			end

			for _, otherWeld in pairs(weldList) do otherWeld.Enabled = true end
		end
	end
	
	if not isCorePart and centralPart.Transparency == 0.5 then centralPart.Transparency = 1 end

	return weldList
end

-- Rig is a cloned version of the model you want to use
function module:MorphRig(char, rig, meta)
	meta = meta or {}

	module:ClearMorph(char)

	local charParts = {}	-- All the parts that have motor6ds inside of them in the character.
	local charMotors = {}	-- The motor 6ds inside the character.

	local rigParts = {}		-- The parts which the motors are to be connected to.
	local rigModels = {}	-- The models which will be welded to the rig parts.

	assert(typeof(char)	== "Instance", "Character does not exist to weld.")
	assert(typeof(rig)	== "Instance", "Rig does not exist to weld.")

	-- Collect charMotors & parts
	for _, inst in pairs(char:GetChildren()) do

		if inst:IsA("BasePart") then
			charParts[inst.Name] = inst
			inst.Transparency = 1

			local motor = inst:FindFirstChildOfClass("Motor6D")
			if inst:FindFirstChildOfClass("Motor6D") then
				charMotors[motor.Name] = motor
			end
		end
	end



	-- Iterate through rig, separate the models, setup the parts.
	for _, inst in pairs(rig:GetDescendants()) do
		local isBasePart = inst:IsA("BasePart")

		if isBasePart then
			inst.Anchored = true
		end

		if isBasePart and charMotors[inst.Name] then
			rigParts[inst.Name] = inst
		elseif inst:IsA("Model") and charParts[inst.Name] and inst.PrimaryPart then
			rigModels[inst.Name] = inst
		end

		if inst:IsA("Model") and not charParts[inst.Name] and inst.PrimaryPart and charParts[inst.Parent.Name] and inst.Parent.PrimaryPart then
			charParts[inst.Name] = inst.PrimaryPart
			local m6d = Instance.new("Motor6D", inst.PrimaryPart)
			m6d.Name = inst.PrimaryPart.Name
			m6d.Part0 = charParts[inst.Parent.Name]
			m6d.Part1 = inst.PrimaryPart

			charMotors[inst.PrimaryPart.Name] = m6d
			rigModels[inst.Name] = inst
		end
	end

	for _, model in pairs(rigModels) do
		model.Parent = char
	end


	-- Edit motor6ds
	local offsets = {}

	for _, motor in pairs(charMotors) do
		if rigParts[motor.Name] then
			local p0 = motor.Part0
			local p1 = motor.Part1

			if script.PlayerRigData.Dummy:FindFirstChild(motor.Parent.Name) then
				local rigOffset0 = plrRigData:GetOffsetFromRoot(p0.Name)
				local rigOffset1 = plrRigData:GetOffsetFromRoot(p1.Name)

				local rigRootPos = rigModels.HumanoidRootPart:FindFirstChildOfClass("Part").CFrame	-- Get the position of the rig
				local jointOffset = rigRootPos:ToObjectSpace(rigParts[motor.Name].CFrame)			-- Distance from rig root to motor

				local jointOffset0 = rigOffset0:ToObjectSpace(jointOffset)	-- Distance from p0 to motor
				local jointOffset1 = rigOffset1:ToObjectSpace(jointOffset)	-- Distance from p1 to motor

				local lastJointCenter = rigParts[p0.Name] or rigModels.HumanoidRootPart:FindFirstChildOfClass("Part")

				offsets[motor] = {jointOffset0, jointOffset1}
			else
				local inst = motor.Parent.Parent
				if not script.PlayerRigData.Dummy:FindFirstChild(motor.Part0.Name) then			-- Other custom rig piece
					offsets[motor] = {motor.Part0.CFrame:inverse() * inst.PrimaryPart.CFrame, CFrame.new(), true}
				else																			-- Basic character part
					local rigOffset0 = plrRigData:GetOffsetFromRoot(motor.Part0.Name)

					local rigRootPos = rigModels.HumanoidRootPart:FindFirstChildOfClass("Part").CFrame	-- Get the position of the rig
					local jointOffset = rigRootPos:ToObjectSpace(rigParts[motor.Name].CFrame)			-- Distance from rig root to motor

					local jointOffset0 = rigOffset0:ToObjectSpace(jointOffset)	-- Distance from p0 to motor

					offsets[motor] = {jointOffset0, CFrame.new(), true}
				end
			end
		end
	end

	-- Weld parts
	for _, model in pairs(rigModels) do
		local centralPart = model.PrimaryPart or model:FindFirstChildOfClass("Part")
		local charPart = charParts[model.Name]

		local visibleRoot = false

		if centralPart and offsets[charMotors[centralPart.Name]] then
			if not charPart:FindFirstChild("MorphOffset") then
				local val = Instance.new("CFrameValue", charPart)
				val.Name = "MorphOffset"
			end
			charPart.MorphOffset.Value = offsets[charMotors[centralPart.Name]][2]
			visibleRoot = offsets[charMotors[centralPart.Name]][3]
		end

		module:MorphPart(charPart, model, {RootIsVisible = visibleRoot, UseManualWelds = meta.UseManualWelds})
	end

	for motor, offset in pairs(offsets) do
		motor.C0 = offset[1]
		motor.C1 = offset[2]
	end
	
	-- Parent new rig parts if applicable
	for i, model in pairs(rigModels) do
		if charParts[model.PrimaryPart.Name] == model.PrimaryPart then
			local part = model.PrimaryPart
			part:SetAttribute("__MorphRoot", true)
			part:SetAttribute("ModelName", model.Name)
			model.Name = part.Name
			part.Parent = char
		end
	end
end

return module
