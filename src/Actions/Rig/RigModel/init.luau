local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local Parse = require(script.Parse)

local T = require(script.types)
type Rig = T.Rig


local m = {}


function m.GetRigFromModel(model: Model): Result<Rig, string>
    local rigModel, err = Parse.ParseRigModel(model):Unwrap()
    if err then return Result.Err(err) end
    return Result.Ok(Parse.RigFromRootRigModel(rigModel))
end


return m