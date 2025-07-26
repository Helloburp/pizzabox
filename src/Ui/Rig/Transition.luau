local rig_actions = script.Parent.Parent.Parent.Actions.Rig
local MorphedRig = setmetatable(
    {
        Parse = require(rig_actions.MorphedRig.Parse)
    },
    {__index = require(rig_actions.MorphedRig)}
)

local LinkedComponent = setmetatable(
    {
        Parse = require(rig_actions.LinkedComponent.Parse),
        Update = require(rig_actions.LinkedComponent.Update)
    },
    {__index = require(rig_actions.LinkedComponent)}
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
        state.LastParsedRig = nil
        oldEditingState.WorkingFolder:Destroy()
    elseif oldEditingState._t == "RigAnimating" then
        state.LastMorphedRig = nil
        state.LastParsedRig = nil
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
    if editingState._t == "RigEditing" then
        state.LastParsedRig = LinkedComponent.Parse.ParseActiveRiggedModel(
            editingState.RootModel, editingState.RootModel
        )

        Selection:Set({editingState.RootModel})

    elseif editingState._t == "RigAnimating" then
        if editingState.BaseRootModel then
            MorphedRig.AnimateExistingRig(
                editingState.BaseRootModel,
                editingState.AnimationRigRootModel
            )
        end

        state.LastParsedRig = LinkedComponent.Parse.ParseActiveRiggedModel(
            editingState.AnimationRigRootModel, editingState.AnimationRigRootModel
        )

        state.LastMorphedRig = (function()
            local morphedRig = MorphedRig.Parse.ParseMorphedRig(
                editingState.AnimationRigRootModel
            ):Ok()
            if not morphedRig then return nil end
            if not game:IsAncestorOf(morphedRig.Rig.Root.Model) then return nil end
            return morphedRig
        end)()

        Selection:Set({editingState.AnimationRigRootModel})
    end

    state.UiState = editingState
end


return m