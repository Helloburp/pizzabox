local rig_actions = script.Parent.Parent.Parent.Actions.Rig
local MorphedRig = setmetatable(
    {
        Parse = require(rig_actions.MorphedRig.Parse)
    },
    {__index = require(rig_actions.MorphedRig)}
)

local Selection = game:GetService("Selection")

local T = require(script.Parent.Parent.Parent["Ui.types"])
type RigState = T.RigState
type RigUiEditingState = T.RigUiEditingState

local m = {}


function m.TransitionEditingState(state: RigState, editingState: RigUiEditingState)
    local oldEditingState = state.UiState

    -- Close the old state
    if oldEditingState._t == "RigEditing" then
        oldEditingState.WorkingFolder:Destroy()
    elseif oldEditingState._t == "RigAnimating" then
        oldEditingState.WorkingFolder:Destroy()

        local morphedRig = MorphedRig.Parse
            .ParseMorphedRig(oldEditingState.AnimationRigRootModel):Ok()
        
        if morphedRig then
            MorphedRig.StopAnimations(morphedRig)
        end

        if oldEditingState.BaseRootModel then
            MorphedRig.StopAnimatingExistingRig(
                oldEditingState.BaseRootModel,
                oldEditingState.AnimationRigRootModel
            )
            oldEditingState.AnimationRigRootModel:Destroy()
        end

        oldEditingState.MorphEffectsController.Cleanup()
    end


    -- Open the new state
    if editingState._t == "NotEditing" then

    elseif editingState._t == "RigEditing" then
        Selection:Set({editingState.RootModel})

    elseif editingState._t == "RigAnimating" then
        if editingState.BaseRootModel then
            MorphedRig.AnimateExistingRig(
                editingState.BaseRootModel,
                editingState.AnimationRigRootModel
            )
        end
        Selection:Set({editingState.AnimationRigRootModel})
    end

    state.UiState = editingState
end


return m