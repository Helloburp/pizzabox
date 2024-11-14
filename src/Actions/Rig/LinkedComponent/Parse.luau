local Result = require(script.Parent.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>


local T = require(script.Parent.types)
type ActiveBone = T.ActiveBone
type BoneDefinition = T.BoneDefinition
type ActiveBeam = T.ActiveBeam
type BeamDefinition = T.BeamDefinition
type ActiveRiggedModel = T.ActiveRiggedModel
type TargetDefinition = T.TargetDefinition
type ActiveLink<I,T> = T.ActiveLink<I,T>



local m = {}


function m.ParseValueAsInstanceType(
	targetValue: TargetDefinition,
	rootModel: Model,
	instanceType: string
): Instance?
	return if targetValue:IsA("ObjectValue") then
			(targetValue.Value and targetValue.Value:IsA(instanceType)) and targetValue.Value or nil
		elseif targetValue:IsA("StringValue") then
			(function()
				for _, descendant in pairs(rootModel:GetDescendants()) do
					if not descendant:IsA(instanceType) then continue end
					if descendant.Name ~= targetValue.Value then continue end
					return descendant
				end
				return nil
			end)()
		else nil
end


function m.ParseTarget(root: Instance): (TargetDefinition)?
	local target = root:FindFirstChild("Target")
	return (target and (target:IsA("ObjectValue") or target:IsA("StringValue")))
        and target
        or nil
end


function m.ParseActiveBone(self: BoneDefinition): ActiveBone?
	local target = m.ParseValueAsInstanceType(self.Target, self.RootModel, "BasePart")
	local children = {}

	for _, child in pairs(self.Component:GetChildren()) do
		if not child:IsA("Bone") then continue end

		local childBoneDefinition = m.ParseBoneDefinition(child, self.RootModel)
		if not childBoneDefinition then continue end

		local childActiveBone = m.ParseActiveBone(childBoneDefinition)
		if not childActiveBone then continue end

		table.insert(children, childActiveBone)
	end

	return if target then
			{Component = self.Component, Target = target, Children = children}
			else nil
end


function m.ParseActiveBeam(self: BeamDefinition): ActiveBeam?
	local target = m.ParseValueAsInstanceType(self.Target, self.RootModel, "Attachment")
	return if target then {Component = self.Component, Target = target} else nil
end


function m.ParseBoneDefinition(bone: Bone, rootModel: Model): BoneDefinition?
	local target = m.ParseTarget(bone)
    if not target then return end

	return {
		Component = bone,
		Target = target,
		RootModel = rootModel
	}
end


function m.ParseBeamDefinition(beam: Beam, rootModel: Model): BeamDefinition?
	local target = m.ParseTarget(beam)
    if not target then return end

    return {
        Component = beam,
        Target = target,
        RootModel = rootModel
    }
end


function m.ParseActiveRiggedModel(model: Model, rootModel: Model): ActiveRiggedModel
	local activeRiggedModel = {
		Model = model,
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


function m.EvaluateActiveLink(
	link: ActiveLink<Instance,Instance>,
	rootModel: Model
): Result<boolean, string>
	if not link.Target:IsDescendantOf(rootModel) then
		return Result.Err(`Target "{link.Target.Name}" is not a descendant of the rig.`)
	end

	return Result.Ok(true)
end


function m.EvaluateBoneNames(rootModel: Model): Result<boolean, string>
	local names = {}
	for _, v in pairs(rootModel:GetDescendants()) do
		if not v:IsA("Bone") then continue end
		if names[v.Name] then
			return Result.Err(
				`Found two or more bones named '{v.Name}'. \z
				You may experience issues when trying to use animation plugins.`
			)
		end
		names[v.Name] = v
	end

	return Result.Ok(true)
end


return m