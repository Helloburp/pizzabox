local T = require(script.Parent.types)
type MorphedRig = T.MorphedRig

local Result = require(script.Parent.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local RigModelParse = require(script.Parent.Parent.RigModel.Parse)

local m = {}


function m.ParseMorphedRig(char: Model): Result<MorphedRig, string>
    local rootModel, err = RigModelParse.ParseRigModel(char):Unwrap()
    if err then return Result.Err(err) end

    local rig = RigModelParse.RigFromRootRigModel(rootModel)

    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildWhichIsA("Animator")

    if not (humanoid and animator) then
        return Result.Err("There is no Humanoid in the character with an Animator instance.")
    end

    return Result.Ok{
        Animator = animator,
        Humanoid = humanoid,
        Rig = rig
    }
end

return m