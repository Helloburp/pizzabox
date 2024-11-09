local T = require(script.Parent.types)
type ActiveBone = T.ActiveBone
type ActiveBeam = T.ActiveBeam
type ActiveRiggedModel = T.ActiveRiggedModel
type BoneDefinition = T.BoneDefinition
type LinkDefinition<I> = T.LinkDefinition<I>
type TargetDefinition = T.TargetDefinition


local m = {}


function m.UpdateBone(self: ActiveBone)
	self.Component.WorldCFrame = self.Target:GetPivot()
	for _, child in pairs(self.Children) do
		m.UpdateBone(child)
	end
end


function m.UpdateBeam(self: ActiveBeam)
    self.Component.Attachment1 = self.Target
end


function m.UpdateActiveRiggedModel(self: ActiveRiggedModel)
	for _, bone in pairs(self.AncestorBones) do
		m.UpdateBone(bone)
	end
	for _, beam in pairs(self.Beams) do
		m.UpdateBeam(beam)
	end
end


function m.UpdateTarget(target: Instance, targetValue: TargetDefinition)
    if targetValue:IsA("StringValue") then
        targetValue.Value = target.Name
    elseif targetValue:IsA("ObjectValue") then
        targetValue.Value = target
    end
end


function m.GetUniqueTargetName(name: string, rootModel: Model)
    local currentName = name
    local iter = 1
    while rootModel:FindFirstChild(currentName, true) do
        currentName = `{name} ({iter})`
        iter += 1
    end

    return currentName
end


return m