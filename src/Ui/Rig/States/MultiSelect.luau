
local inst_root = script.Parent.Parent.Parent.Parent
local Iris = require(inst_root.Parent.Packages.Iris)

local Instantiate = require(script.Parent.Instantiate)
local LinkedComponent = require(inst_root.Actions.Rig.LinkedComponent)

local T = require(inst_root["Ui.types"])
type RigState = T.RigState
type RigUiEditingState = T.RigUiEditingState

local MAX_RIG_NAMES_DISPLAYED = 2

local m = {}

function m.MultiSelectState(state: RigState): RigUiEditingState?
    assert(state.UiState._t == "MultiSelect")

    local transition: RigUiEditingState? = nil

    state.UiState.RigRootModels = _updateRootModels(state.UiState.RigRootModels)
    for _, model in state.UiState.RigRootModels do
        LinkedComponent.UpdateRigAttachments(model)
    end

    if Iris.Button("Return").clicked() then
        transition = Instantiate.NewNotEditingState()
    end

    return transition
end


function m.WindowName(state: RigState)
    assert(state.UiState._t == "MultiSelect")
    local modelCount = #state.UiState.RigRootModels
    local modelNames = {}
    for i, model in state.UiState.RigRootModels do
        if i > MAX_RIG_NAMES_DISPLAYED then break end
        table.insert(modelNames, model.Name)
    end

    return `Previewing {table.concat(modelNames, ", ")}\z
        {if modelCount > MAX_RIG_NAMES_DISPLAYED
            then `, plus {modelCount - MAX_RIG_NAMES_DISPLAYED} more...`
            else ""}`
end


function _updateRootModels(models: {Model}): {Model}
    local newModels = {}
    for _, model in models do
        if not game.Workspace:IsAncestorOf(model) then continue end
        table.insert(newModels, model)
    end
    return newModels
end


return m