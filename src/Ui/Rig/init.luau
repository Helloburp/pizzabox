local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local m = {}

local Result = require(script.Parent.Parent.Result)

local States = {
    NotEditing = require(script.States.NotEditing),
    RigEditing = require(script.States.RigEditing),
    RigAnimating = require(script.States.RigAnimating),
    MultiSelect = require(script.States.MultiSelect),
    Instantiate = require(script.States.Instantiate)
}

local Transition = require(script.Transition)

local T = require(script.Parent.Parent["Ui.types"])
type RigState = T.RigState
type State = T.State
type RigUiSelectedComponent = T.RigUiSelectedComponent

type RigUiEditingState = T.RigUiEditingState
type Result<T,E> = Result.Result<T,E>


function m.Cycle(state: State)
    local rigState = state.RigState
    local uiStateType = rigState.UiState._t
    local subWindowName = if uiStateType ~= "NotEditing"
        then (
            if uiStateType == "RigEditing" then
                `(Editing {rigState.UiState.RootModel.Name})`
            elseif uiStateType == "RigAnimating" then
                `(Animating {rigState.UiState.AnimationRigRootModel.Name})`
            elseif uiStateType == "MultiSelect" then
                `({States.MultiSelect.WindowName(rigState)})`
            else error(`Invalid state: {uiStateType}`)
        )
        else ""

    m.CycleCleanup(rigState)
    Iris.Window(`Rig {subWindowName}`, {isOpened = state.WindowStates.Rig})

    local transition =
        if uiStateType == "NotEditing" then States.NotEditing.NotEditingState(rigState)
        elseif uiStateType == "RigEditing" then States.RigEditing.RigMode(rigState)
        elseif uiStateType == "RigAnimating" then States.RigAnimating.AnimatorMode(rigState)
        elseif uiStateType == "MultiSelect" then States.MultiSelect.MultiSelectState(rigState)
        else error(`Invalid state: {uiStateType}`)
    
    if transition then
        Transition.TransitionEditingState(rigState, transition)
    end

    Iris.End()
end


function m.CycleCleanup(state: RigState)
    if state.LastRigVisualizer then
        state.LastRigVisualizer:Destroy()
        state.LastRigVisualizer = nil
    end
end

function m.Cleanup(state: RigState)
    m.CycleCleanup(state)
    if state.UiState._t ~= "NotEditing" then
        Transition.TransitionEditingState(state, States.Instantiate.NewNotEditingState())
    end
end


function m.State(): RigState
    return {
        RigVisualizerState = Iris.State(false),
        LiveLinkedComponentUpdatesState = Iris.State(true),
        AnimationPlayingState = Iris.State(false),
        CamShakeEnabledState = Iris.State(false),
        UiState = States.Instantiate.NewNotEditingState(),
    }
end


return m