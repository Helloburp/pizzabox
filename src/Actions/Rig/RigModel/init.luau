local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local Parse = require(script.Parse)

local T = require(script.types)
type Rig = T.Rig


local m = {}


function m.GetRigFromMainRigModel(model: Model): Result<Rig, string>
    local rootModel = model:FindFirstChild("HumanoidRootPart")
    if not (rootModel and rootModel:IsA("Model")) then
        return Result.Err("Did not find a model named HumanoidRootPart in this rig.")
    end

    local rigModel, err = Parse.ParseRigModel(rootModel):Unwrap()
    if err then return Result.Err(err) end
    return Result.Ok(Parse.RigFromRootRigModel(rigModel))
end


return m