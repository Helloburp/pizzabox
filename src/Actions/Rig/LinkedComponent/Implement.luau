local Result = require(script.Parent.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local Parse = require(script.Parent.Parse)

local T = require(script.Parent.types)
type BoneDefinition = T.BoneDefinition
type BeamDefinition = T.BeamDefinition
type TargetDefinition = T.TargetDefinition



local m = {}


function _setupStringValue(component: Instance, target: TargetDefinition?)
    if target and target:IsA("ObjectValue") then
        target:Destroy()
    end

    local newTarget = (target and target:IsA("StringValue"))
        and target
        or Instance.new("StringValue", component)
    newTarget.Name = "Target"
    newTarget.Value = component.Name
end


function m.ImplementBone(
    bone: Bone,
    targetPart: BasePart,
    rootModel: Model
): Result<BoneDefinition, string>
    local existingBone = Parse.ParseBoneDefinition(bone, rootModel)
    _setupStringValue(bone, existingBone and existingBone.Target or nil)

    local boneDefinition = Parse.ParseBoneDefinition(bone, rootModel)
    return if boneDefinition
        then Result.Ok(boneDefinition)
        else Result.Err("Unable to create BoneDefinition.")
end


function m.ImplementBeam(
    beam: Beam,
    attachment: Attachment,
    rootModel: Model
)
    local existingBeam = Parse.ParseBeamDefinition(beam, rootModel)
    _setupStringValue(beam, existingBeam and existingBeam.Target or nil)

    local beamDefinition = Parse.ParseBeamDefinition(beam, rootModel)
    return if beamDefinition
        then Result.Ok(beamDefinition)
        else Result.Err("Unable to create BeamDefinition.")
end


return m