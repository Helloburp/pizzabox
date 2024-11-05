local T = require(script.Parent["Parse.types"])
type ActiveBone = T.ActiveBone
type ActiveBeam = T.ActiveBeam
type ActiveRiggedModel = T.ActiveRiggedModel


local m = {}


function m.UpdateBone(self: ActiveBone)
	self.Bone.WorldCFrame = self.Target:GetPivot()
	for _, child in pairs(self.Children) do
		m.UpdateBone(child)
	end
end


function m.UpdateBeam(self: ActiveBeam)
    self.Beam.Attachment1 = self.Target
end


function m.UpdateActiveRiggedModel(self: ActiveRiggedModel)
	for _, bone in pairs(self.AncestorBones) do
		m.UpdateBone(bone)
	end
	for _, beam in pairs(self.Beams) do
		m.UpdateBeam(beam)
	end
end


return m