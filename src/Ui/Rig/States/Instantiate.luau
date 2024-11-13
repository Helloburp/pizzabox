local inst_root = script.Parent.Parent.Parent.Parent
local Output = require(inst_root.Ui.Output)
local T = require(inst_root["Ui.types"])

type RigUiEditingState = T.RigUiEditingState


local m = {}


function m.NewWorkingFolder(parent: Instance): Folder
    local folder = Instance.new("Folder", parent)
    folder.Name = "__pizzabox_working"
    return folder
end


function m.NewRigEditingState(rootRigModel: Model): RigUiEditingState
    return {
        _t = "RigEditing",
        Output = Output.New(),
        RootModel = rootRigModel,
        WorkingFolder = m.NewWorkingFolder(rootRigModel)
    }
end

function m.NewRigAnimatingState(animatingRig: Model, rootRigModel: Model?): RigUiEditingState
    return {
        _t = "RigAnimating",
        Output = Output.New(),
        BaseRootModel = rootRigModel,
        AnimationRigRootModel = animatingRig,
        WorkingFolder = m.NewWorkingFolder(animatingRig)
    }
end

function m.NewNotEditingState(): RigUiEditingState
    return {
        _t = "NotEditing",
        Output = Output.New()
    }
end


return m