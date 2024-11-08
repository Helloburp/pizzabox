local T = require(script.Parent["RigComponents.types"])
type RigModel = T.RigModel

local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>


local m = {}

function m.ParseRigModel(model: Model): Result<RigModel, string>
    local joint = (model.PrimaryPart and model.PrimaryPart.Parent == model)
        and model.PrimaryPart
        or nil
    
    if not joint then
        return Result.Err("Joint was not found, or is not a child of the model.")
    end

    local children: {RigModel} = {}

    for _, child in pairs(model:GetChildren()) do
        if not child:IsA("Model") then continue end
        local childRigModel = m.ParseRigModel(child):Ok()
        if not childRigModel then continue end
        table.insert(children, childRigModel)
    end

    return Result.Ok{
        Model = model,
        Joint = joint,
        Children = children
    }
end


function m.ParseRig()
end


return m