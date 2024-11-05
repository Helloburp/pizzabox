local T = require(script.Parent["Parse.types"])
type ActiveBone = T.ActiveBone
type BoneDefinition = T.BoneDefinition
type ActiveBeam = T.ActiveBeam
type BeamDefinition = T.BeamDefinition
type ActiveRiggedModel = T.ActiveRiggedModel


local m = {}


function m.ParseValueAsInstanceType(
	targetValue: StringValue | ObjectValue,
	rootModel: Model,
	instanceType: string
): Instance?
	return if targetValue:IsA("ObjectValue") then
			(targetValue.Value and targetValue.Value:IsA(instanceType)) and targetValue.Value or nil
		elseif targetValue:IsA("StringValue") then
			rootModel:FindFirstChild(targetValue.Value, true)
		else nil
end


function m.ParseTarget(root: Instance): (StringValue | ObjectValue)?
	local target = root:FindFirstChild("Target")
	return (target and (target:IsA("ObjectValue") or target:IsA("StringValue")))
        and target
        or nil
end


function m.ParseActiveBone(self: BoneDefinition): ActiveBone?
	local target = m.ParseValueAsInstanceType(self.Target, self.RootModel, "PVInstance")
	local children = {}

	for _, child in pairs(self.Bone:GetChildren()) do
		if not child:IsA("Bone") then continue end

		local childBoneDefinition = m.ParseBoneDefinition(child, self.RootModel)
		if not childBoneDefinition then continue end

		local childActiveBone = m.ParseActiveBone(childBoneDefinition)
		if not childActiveBone then continue end

		table.insert(children, childActiveBone)
	end

	return if target then {Bone = self.Bone, Target = target, Children = children} else nil
end


function m.ParseActiveBeam(self: BeamDefinition): ActiveBeam?
	local target = m.ParseValueAsInstanceType(self.Target, self.RootModel, "Attachment")
	return if target then {Beam = self.Beam, Target = target} else nil
end


function m.ParseBoneDefinition(bone: Bone, rootModel: Model): BoneDefinition?
	local target = m.ParseTarget(bone)
    if not target then return end

	return {
		Bone = bone,
		Target = target,
		RootModel = rootModel
	}
end


function m.ParseBeamDefinition(beam: Beam, rootModel: Model): BeamDefinition?
	local target = m.ParseTarget(beam)
    if not target then return end

    return {
        Beam = beam,
        Target = target,
        RootModel = rootModel
    }
end


function m.ParseActiveRiggedModel(model: Model, rootModel: Model): ActiveRiggedModel
	local activeRiggedModel = {
		Model = model,
		RootModel = rootModel,
		Beams = {},
		AncestorBones = {}
	}

	local function _recurse(inst: Instance)
		for _, child in pairs(inst:GetChildren()) do

			local parsedBone = child:IsA("Bone") and m.ParseBoneDefinition(child, rootModel) or nil
			local activeBone = parsedBone and m.ParseActiveBone(parsedBone)
			if activeBone then
				table.insert(activeRiggedModel.AncestorBones, activeBone)
				continue
			end

			local parsedBeam = child:IsA("Beam") and m.ParseBeamDefinition(child, rootModel) or nil
			local activeBeam = parsedBeam and m.ParseActiveBeam(parsedBeam)
			if parsedBeam then
				table.insert(activeRiggedModel.Beams, activeBeam)
			end

			_recurse(child)
		end
	end

	_recurse(model)

	return activeRiggedModel
end


return m