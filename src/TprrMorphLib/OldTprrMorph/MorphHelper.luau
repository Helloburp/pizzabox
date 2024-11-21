-- Module with helpful methods for dealing with characters that have been morphed.

local module = {}

module.ValidPartNames = {
	["UpperTorso"] = true,
	["LowerTorso"] = true,
	["Head"] = true,
	["LeftUpperArm"] = true,
	["LeftLowerArm"] = true,
	["LeftHand"] = true,
	["RightUpperArm"] = true,
	["RightLowerArm"] = true,
	["RightHand"] = true,
	["LeftUpperLeg"] = true,
	["LeftLowerLeg"] = true,
	["LeftFoot"] = true,
	["RightUpperLeg"] = true,
	["RightLowerLeg"] = true,
	["RightFoot"] = true,
	["HumanoidRootPart"] = true
}

function module:GetMorphModels(char)
	local morphModels = {}
	for _, v in pairs(char:GetChildren()) do
		if v:IsA("Model") and v:GetAttribute("__MorphModel") then table.insert(morphModels, v) end
	end
	return morphModels
end

-- Gets the motor6ds of the entire model. Indexes them by part name.
function module:GetMotor6Ds(char)
	local motors = {}
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("Motor6D") then
			motors[v.Part1] = v
		end
	end
	return motors
end

-- Gets all joints which are not part of the basic R15 rig.
function module:GetNonStandardMotor6Ds(char)
	local motors = module:GetMotor6Ds(char)
	for part, motor in pairs(motors) do
		if module.ValidPartNames[part.Name] then motors[part] = nil end
	end
	return motors
end

-- Returns the part name from the list of ValidPartNames that a motor is connected to.
function module:GetR15PartFromMotor(char, motor)
	local currentMotor = motor
	while currentMotor and currentMotor.Part0 and not module.ValidPartNames[currentMotor.Part0.Name] do
		if not currentMotor.Part0 then currentMotor = nil break end
		currentMotor = currentMotor.Part0:FindFirstChildOfClass("Motor6D")
	end
	
	if currentMotor then
		return currentMotor.Part0
	else
		return nil
	end
end

function module:GetNonStandardMotor6DsFromR15Part(char, partName)
	local motors = module:GetNonStandardMotor6Ds(char)
	for _part, motor in pairs(motors) do
		local part = module:GetR15PartFromMotor(char, motor)
		if not (part and part.Name == partName) then motors[_part] = nil end
	end
	return motors
end

function module:GetNonStandardModelsFromR15Part(char, partName)
	local motors = module:GetNonStandardMotor6DsFromR15Part(char, partName)
	local models = {}
	for part, motor in pairs(motors) do
		models[part] = motor:FindFirstAncestorWhichIsA("Model")
	end
	return models
end

return module
