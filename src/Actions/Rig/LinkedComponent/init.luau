local Update = require(script.Update)
local Parse = require(script.Parse)
local Implement = require(script.Implement)
local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local T = require(script.types)
type BoneDefinition = T.BoneDefinition


local RigModelInstantiate = require(script.Parent.RigModel.Instantiate)


local m = {}


function m.UpdateRigAttachments(model: Model)
    local riggedModel = Parse.ParseActiveRiggedModel(model, model)
    Update.UpdateActiveRiggedModel(riggedModel)
end


function m.NewBoneTarget(bone: Bone, rootModel: Model): Result<BoneDefinition,string>
    local name = Update.GetUniqueTargetName(`target_{bone.Name}`, rootModel)
    local targetParent = bone:FindFirstAncestorWhichIsA("Model")
    if not (
        targetParent and
        (targetParent == rootModel or targetParent:IsDescendantOf(rootModel))
    ) then
        return Result.Err("The bone must be inside the provided rig.")
    end

    local target = RigModelInstantiate.Joint(name, bone.WorldCFrame, 0.124)
    target.Parent = targetParent

    return Implement.ImplementBone(bone, target, rootModel)
end


function m.NewBeamTarget(beam: Beam, rootModel: Model)
    local name = Update.GetUniqueTargetName(`target_{beam.Name}`, rootModel)
    local targetParent = beam:FindFirstAncestorWhichIsA("Model")
    if not (
        targetParent and
        (targetParent == rootModel or targetParent:IsDescendantOf(rootModel))
    ) then
        return Result.Err("The beam must be inside the provided rig.")
    end
    local joint = RigModelInstantiate.Joint(name, targetParent:GetPivot(), 0.124)
    joint.Parent = targetParent

    local target = Instance.new("Attachment", joint)
    target.Name = name

    return Implement.ImplementBeam(beam, target, rootModel)
end


return m