local module = {}

module.RigTree = {
	["HumanoidRootPart"] = {
		["LowerTorso"] = {
			["UpperTorso"] = {},
			["Head"] = {},

			["RightUpperArm"] = {["RightLowerArm"] = {["RightHand"] = {}}},
			["LeftUpperArm"] = {["LeftLowerArm"] = {["LeftHand"] = {}}},
			["RightUpperLeg"] = {["RightLowerLeg"] = {["RightFoot"] = {}}},
			["LeftUpperLeg"] = {["LeftLowerLeg"] = {["LeftFoot"] = {}}}
		}
	}
}

module.JointPartIndex = {
	["ModelRoot"]		= "HumanoidRootPart",
	["Root"]			= "LowerTorso",
	["Waist"]			= "UpperTorso",
	["Neck"]			= "Head",

	["RightShoulder"]	= "RightUpperArm",
	["RightElbow"]		= "RightLowerArm",
	["RightWrist"]		= "RightHand",

	["LeftShoulder"]	= "LeftUpperArm",
	["LeftElbow"]		= "LeftLowerArm",
	["LeftWrist"]		= "LeftHand",

	["RightHip"]		= "RightUpperLeg",
	["RightKnee"]		= "RightLowerLeg",
	["RightAnkle"]		= "RightFoot",

	["LeftHip"]			= "LeftUpperLeg",
	["LeftKnee"]		= "LeftLowerLeg",
	["LeftAnkle"]		= "LeftFoot",
}

-- Returns whether or not a parnet has all the necessary joint components for a rig.
function module:TestPartListIntegrity(parent)
	local filledList = {}

	for jointName, partName in pairs(module.JointPartIndex) do
		filledList[jointName] = false
	end

	for _, part in pairs(parent:GetChildren()) do
		if part:IsA("BasePart") and module.JointPartIndex[part.Name] then
			filledList[part.Name] = true
		else
			return false, string.format("member '%s' is not a proper joint name, or is not a part.", part.Name)
		end
	end

	for _, val in pairs(filledList) do
		if not val then return false, "Some joints are missing." end
	end

	return true
end

function module:TestModelListIntegrity(parent)
	for _, model in pairs(parent:GetChildren()) do
		if not (model:IsA("Model") and module.JointPartIndex[model.Name]) then
			return false, string.format("member '%s' is not a proper joint name, or is not a model.", model.Name)
		end
	end

	return true
end

return module
