local Update = require(script.Update)
local Parse = require(script.Parse)
local Implement = require(script.Implement)
local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local T = require(script.types)
type BoneDefinition = T.BoneDefinition
type BeamDefinition = T.BeamDefinition

local T_RIGMODEL = require(script.Parent.RigModel.types)
type RigModel = T_RIGMODEL.RigModel


local RigModelInstantiate = require(script.Parent.RigModel.Instantiate)

local JOINT_SIZE = 0.124


local m = {}


function m.UpdateRigAttachments(model: Model)
    local riggedModel = Parse.ParseActiveRiggedModel(model, model)
    Update.UpdateActiveRiggedModel(riggedModel)
end


function m.NewBoneTarget(bone: Bone, rootModel: Model): Result<BoneDefinition,string>
    local targetParentResult = _getTargetParent(bone, rootModel)
    local targetParent = targetParentResult:Ok()
    if not targetParent then return targetParentResult end

    local name = Update.GetUniqueTargetName(`b_{bone.Name}`, rootModel)
    local joint = RigModelInstantiate.Joint(name, bone.WorldCFrame, JOINT_SIZE)
    joint.Parent = targetParent

    return Implement.ImplementBone(bone, joint, rootModel)
end


function m.NewBoneModel(bone: Bone, rootModel: Model): Result<BoneDefinition,string>
    local targetParentResult = _getTargetParent(bone, rootModel)
    local targetParent = targetParentResult:Ok()
    if not targetParent then return targetParentResult end

    local name = Update.GetUniqueTargetName(`b_{bone.Name}`, rootModel)
    local rigModel = RigModelInstantiate.NewRigModel(`m_{name}`, name, JOINT_SIZE, bone.WorldCFrame)

    return Implement.ImplementBone(bone, rigModel.Joint, rootModel)
end


function m.NewBoneModelRecursive(bone: Bone, rootModel: Model): Result<boolean,string>
    local err = m.NewBoneModel(bone, rootModel):Err()
    if err then return Result.Err(`'{bone.Name}': {err}`) end
    
    for _, child in pairs(bone:GetChildren()) do
        if not child:IsA("Bone") then continue end
        local childErr = m.NewBoneModelRecursive(child, rootModel):Err()
        if childErr then return Result.Err(childErr) end
    end

    return Result.Ok(true)
end


function m.NewBeamTarget(beam: Beam, rootModel: Model): Result<BeamDefinition,string>
    local targetParentResult = _getTargetParent(beam, rootModel)
    local targetParent = targetParentResult:Ok()
    if not targetParent then return targetParentResult end

    local name = Update.GetUniqueTargetName(`beam_{beam.Name}`, rootModel)
    local joint = RigModelInstantiate.Joint(name, targetParent:GetPivot(), JOINT_SIZE)
    joint.Parent = targetParent

    local target = Instance.new("Attachment", joint)
    target.Name = joint.Name

    return Implement.ImplementBeam(beam, target, rootModel)
end


function _getTargetParent(inst: Instance, rootModel: Model): Result<Model,string>
    local targetParent = inst:FindFirstAncestorWhichIsA("Model")
    return if (
        targetParent and
        (targetParent == rootModel or targetParent:IsDescendantOf(rootModel))
    )
        then Result.Ok(targetParent)
        else Result.Err(`The {inst.ClassName} must be inside the provided rig.`)
end


function _newJointForTarget(inst: Instance, rootModel: Model, cf: CFrame?): Result<BasePart,string>
    local name = Update.GetUniqueTargetName(`target_{inst.Name}`, rootModel)
    local targetParent = _getTargetParent(inst, rootModel)
    if targetParent then
        return Result.Err(`The {inst.ClassName} must be inside the provided rig.`)
    end
    local joint = RigModelInstantiate.Joint(name, cf or targetParent:GetPivot(), 0.124)
    joint.Parent = targetParent
    return Result.Ok(joint)
end


return m