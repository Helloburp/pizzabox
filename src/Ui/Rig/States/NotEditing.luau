
local inst_rig_actions = script.Parent.Parent.Parent.Parent.Actions.Rig
local RigSelection = require(inst_rig_actions.RigSelection)
type RigSelection = RigSelection.RigSelection

local NewStandardRig = require(inst_rig_actions.NewStandardRig)

local inst_root = script.Parent.Parent.Parent.Parent
local Output = require(inst_root.Ui.Output)
local Iris = require(inst_root.Parent.Packages.Iris)
local ActionHandling = require(inst_root.Ui.ActionHandling)
local MacroElements = require(inst_root.Ui.IrisMacroElements)

local Selection = game:GetService("Selection")

local Instantiate = require(script.Parent.Instantiate)

local T = require(inst_root["Ui.types"])
type RigState = T.RigState
type RigUiEditingState = T.RigUiEditingState


local m = {}


function m.NotEditingState(state: RigState): RigUiEditingState?
    assert(state.UiState._t == "NotEditing")

    local transition: RigUiEditingState? = nil

    local selectionOutput = _selectionView(state)
    Iris.Separator()
    _utils(state)
    Iris.Separator()
    MacroElements.OutputText(Output.Format(state.UiState.Output))

    if selectionOutput and selectionOutput.EditButtonClicked then
        if selectionOutput.SelectionResult._t == "StaticRig" then
            transition = Instantiate.NewRigEditingState(selectionOutput.SelectionResult.Rig)
        elseif selectionOutput.SelectionResult._t == "AnimatedRig" then
            transition = Instantiate.NewRigAnimatingState(
                selectionOutput.SelectionResult.AnimatedRig, nil, state.CamShakeEnabledState
            )
        elseif selectionOutput.SelectionResult._t == "MultiSelect" then
            local allRoots = {}
            for _, model in selectionOutput.SelectionResult.AnimatedRigs do
                table.insert(allRoots, model)
            end
            for _, model in selectionOutput.SelectionResult.StaticRigs do
                table.insert(allRoots, model)
            end
            transition = Instantiate.NewMultiSelectState(allRoots)
        end
    end

    return transition
end


function _selectionView(
    state: RigState
): {
    EditButtonClicked: boolean,
    SelectionResult: RigSelection
}?
    assert(state.UiState._t == "NotEditing")
    local selection, err = RigSelection.ParseAll(Selection:Get()):Unwrap()

    local textArgs = if selection and selection._t == "MultiSelect" then {
            `Multiple rigs selected.`
        } elseif selection and selection._t == "StaticRig" then {
            `Rig selected: {selection.Rig.Name}`,
        } elseif selection and selection._t == "AnimatedRig" then {
            `Animated Rig selected: {selection.AnimatedRig.Name}`
        } else {
            err or "No model selected.",
        }

    Iris.Text(textArgs)
    if not selection then return end
    local output = {
        EditButtonClicked = false,
        SelectionResult = selection
    }

    Iris.Separator()
    
    if Iris.Button(if selection._t == "StaticRig"
        then "Enter Edit Mode"
        elseif selection._t == "AnimatedRig" then "Enter Animation Mode"
        else "Enter Multi-Rig Preview"
    ).clicked() then
        output.EditButtonClicked = true
    end

    return output
end


function _utils(state: RigState)
    assert(state.UiState._t == "NotEditing")
    if Iris.Button("New Standard Rig").clicked() then
        ActionHandling.DoRecordedAction("New Standard Rig", function()
            local frontCf = game.Workspace.CurrentCamera.CFrame
                * CFrame.new(0, 0, -10)
            local rig = NewStandardRig.New(
                CFrame.new(frontCf.X, frontCf.Y, frontCf.Z)
            )
            Selection:set({rig})
        end)
    end
end


return m