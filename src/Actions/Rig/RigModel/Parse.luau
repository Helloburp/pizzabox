local T = require(script.Parent.types)
type RigModel = T.RigModel
type Rig = T.Rig
type RigNameEvaluation = T.RigNameEvaluation

local inst_linked = script.Parent.Parent.LinkedComponent
local ParseLinked = require(inst_linked.Parse)


local Result = require(script.Parent.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>


local m = {}

function m.ParseRigModel(model: Model): Result<RigModel, string>
    local joint = (model.PrimaryPart and model.PrimaryPart.Parent == model)
        and model.PrimaryPart
        or nil
    
    if not joint then
        return Result.Err(`PrimaryPart was not found, or is not a child of model '{model.Name}'.`)
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


function m.EvaluateRigNames(rig: Rig): Result<RigNameEvaluation, string>
    local modelNames, jointNames = {}, {}
    
    local function _recurse(model: RigModel): Result<boolean, string>
        local modelName, jointName = model.Model.Name, model.Joint.Name
        if modelNames[modelName] then
            return Result.Err(`There are multiple instances of a Model named "{modelName}"!`)
        elseif jointNames[jointName] then
            return Result.Err(`There are multiple instances of a PrimaryPart named "{jointName}"!`)
        end

        modelNames[modelName] = model
        jointNames[jointName] = model

        for _, child in pairs(model.Children) do
            local result = _recurse(child)
            if result:Err() then return result end
        end

        return Result.Ok(true)
    end

    local e = _recurse(rig.Root):Err()
    return if e then Result.Err(e) else Result.Ok{
        RigModelsByModelName = modelNames,
        RigModelsByJointName = jointNames
    }
end


function m.RigFromRootRigModel(rootRigModel: RigModel): Rig
    return {
        LinkedComponents = ParseLinked.ParseActiveRiggedModel(
            rootRigModel.Model,
            rootRigModel.Model
        ),
        Root = rootRigModel
    }
end


function m.ContainsModel(rootRigModel: RigModel, model: Model): RigModel?
    if rootRigModel.Model == model then return rootRigModel end

    for _, child in pairs(rootRigModel.Children) do
        local containingChild = m.ContainsModel(child, model)
        if containingChild then return containingChild end
    end

    return nil
end


function m.ContainsJoint(rootRigModel: RigModel, joint: BasePart): RigModel?
    if rootRigModel.Joint == joint then return rootRigModel end

    for _, child in pairs(rootRigModel.Children) do
        local containingChild = m.ContainsJoint(child, joint)
        if containingChild then return containingChild end
    end

    return nil
end


return m