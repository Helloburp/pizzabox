local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local MacroElements = require(script.Parent.IrisMacroElements)
local T = require(script.Parent.Parent["Ui.types"])
local m = {}

local inst_rig_actions = script.Parent.Parent.Actions.Rig
local RigSelection = require(inst_rig_actions.RigSelection)
local NewStandardRig = require(inst_rig_actions.NewStandardRig)

local Selection = game:GetService("Selection")

local LinkedComponent = require(inst_rig_actions.LinkedComponent)
local MorphedRig = require(inst_rig_actions.MorphedRig)
local RigModel = require(inst_rig_actions.RigModel)
local MorphedRigParse = require(inst_rig_actions.MorphedRig.Parse)

local T_RIGMODEL = require(inst_rig_actions.RigModel.types)
type RigModel = T_RIGMODEL.RigModel
type Rig = T_RIGMODEL.Rig


local ActionHandling = require(script.Parent.ActionHandling)
local Output = require(script.Parent.Output)

local Result = require(script.Parent.Parent.Result)

type RigState = T.RigState
type State = T.State
type RigUiTransition = T.RigUiTransition
type RigUiMode = T.RigUiMode
type RigUiEditingState = T.RigUiEditingState
type Result<T,E> = Result.Result<T,E>


function _transitionMode(state: RigState, mode: RigUiMode)
    assert(state.UiState._t == "RigEditing")
    if mode._t == "Animated" then
        assert(state.UiState.Mode._t == "Static")
        MorphedRig.BeginAnimationMode(
            state.UiState.RootModel,
            mode.AnimationRigRootModel
        )
    elseif mode._t == "Static" then
        assert(state.UiState.Mode._t == "Animated")
        MorphedRig.EndAnimationMode(
            state.UiState.RootModel,
            state.UiState.Mode.AnimationRigRootModel
        )
    end

    state.UiState.Mode = mode
end


function _transitionEditingState(state: RigState, editingState: RigUiEditingState)
    if editingState._t == "NotEditing" then
        assert(state.UiState._t == "RigEditing")
        if state.UiState.Mode._t == "Animated" then
            _transitionMode(state, {_t = "Static", Output = Output.New()})
        end
    elseif editingState._t == "RigEditing" then
        assert(state.UiState._t == "NotEditing")
    end

    state.UiState = editingState
end


function _rigAnimator(state: RigState): RigUiTransition?
    assert(state.UiState._t == "RigEditing")
    assert(state.UiState.Mode._t == "Animated")

    local transition: RigUiTransition? = nil

    local morphedRig = MorphedRigParse
        .ParseMorphedRig(state.UiState.Mode.AnimationRigRootModel):Ok()
    
    if not morphedRig then
        local newOutput = Output.New()
        Output.Set(
            newOutput.Warnings, "MODE_TRANSITION",
            "Animation Mode exited unexpectedly, as the Animation Rig was unable to be validated."
        )
        return {
            _t = "Mode",
            Value = { _t = "Static", Output = newOutput }
        }
    end


    if Iris.Button("Exit Animation Mode") then
        transition = {
            _t = "Mode",
            Value = { _t = "Static", Output = Output.New() }
        }
    end


    return transition
end


function _rigEditor(state: RigState): RigUiTransition?
    assert(state.UiState._t == "RigEditing")
    assert(state.UiState.Mode._t == "Static")

    local rig = RigModel.GetRigFromModel(state.UiState.RootModel):Ok()
    if not rig then
        local newOutput = Output.New()
        Output.Set(
            newOutput.Warnings, "MODE_TRANSITION",
            "Editing exited unexpectedly, as the Rig was unable to be validated."
        )
        return {
            _t = "EditingState",
            Value = {
                _t = "NotEditing", Output = newOutput
            }
        }
    end

    local output = state.UiState.Mode.Output
    local transition: RigUiTransition? = nil

    if Iris.Button("Enter Animation Mode").clicked() then
        local newModel, err = MorphedRig.NewAnimationRig(state.UiState.RootModel):Unwrap()
        if err then
            output.Errors["NEW_ANIM_RIG_ERROR"] = err
        else
            transition = {
                _t = "Mode",
                Value = {
                    _t = "Animated", AnimationRigRootModel = newModel.Rig.Root.Model
                }
            }
        end

    end

    Iris.Separator()
    Iris.Text("Mesh Deformation & Beams")
    _rigEditorLiveLinkedComponentUpdateToggle(state)

    local outputText = Output.Format(output)

    if outputText ~= "" then
        Iris.Separator()
        MacroElements.WrappedRichText(outputText)
    end


    return transition
end


function _rigEditorLiveLinkedComponentUpdateToggle(state: RigState)
    assert(state.UiState._t == "RigEditing")
    if Iris.Checkbox(
        {
            if state.LiveLinkedComponentUpdatesState:get()
                then "Enable Preview"
                else "Disable Preview"
        },
        {isChecked = state.LiveLinkedComponentUpdatesState}
    ).isChecked:get() then
        LinkedComponent.UpdateRigAttachments(state.UiState.RootModel)
    end
end


function _notEditing(state: RigState): RigUiTransition?
    assert(state.UiState._t == "NotEditing")

    local transition: RigUiTransition? = nil

    _notEditingSelectionView(state)
    Iris.Separator()
    _notEditingUtils(state)

    return transition
end


function _notEditingSelectionView(state: RigState)
    assert(state.UiState._t == "NotEditing")
    local selection, err = RigSelection.Parse():Unwrap()
    local rig = selection and selection.Rig

    local textArgs = if selection and selection.Joints then {
            `Rig and Joints Selected: {selection.Rig.Name}, {selection.Joints.Name}`,
        } elseif selection and not selection.Joints then {
            `Rig selected: {selection.Rig.Name}`,
        } else {
            err or "No model selected.",
        }

    Iris.Text(textArgs)
    if not rig then return end

    Iris.Separator()

end


function _notEditingUtils(state: RigState)
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


function m.Cycle(state: State)
    Iris.Window("Rig", {isOpened = state.WindowStates.Rig})
    Iris.End()
end


function m.State(): RigState
    return {
        RigVisualizerState = Iris.State(false),
        LiveLinkedComponentUpdatesState = Iris.State(false),
        AnimationPlayingState = Iris.State(false),
        UiState = {
            _t = "NotEditing",
            Output = Output.New()
        },
    }
end


return m