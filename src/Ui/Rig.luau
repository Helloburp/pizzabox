local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local T = require(script.Parent.Parent["Ui.types"])
local m = {}

local inst_rig_actions = script.Parent.Parent.Actions.Rig
local RigSelection = require(inst_rig_actions.RigSelection)
local MakeAnimatableRig = require(inst_rig_actions.MakeAnimatableRig)
local NewStandardRig = require(inst_rig_actions.NewStandardRig)
local Selection = game:GetService("Selection")
local LinkedComponent = require(inst_rig_actions.LinkedComponent)

local ActionHandling = require(script.Parent.ActionHandling)


function _selectionView(state: T.State)
    local selection, err = RigSelection.Parse():Unwrap()

    local textArgs = if selection and selection.Joints then {
            `Rig and Joints Selected: {selection.Rig.Name}, {selection.Joints.Name}`,
        } elseif selection and not selection.Joints then {
            `Rig selected: {selection.Rig.Name}`,
        } else {
            err or "No model selected.",
        }

    Iris.Text(textArgs)

    local rig, _joints =
        selection and selection.Rig,
        selection and selection.Joints
    if rig then
        Iris.Separator()
        if Iris.Button("Make Animatable Rig").clicked() then
            ActionHandling.DoRecordedAction("Make Rig", function()
                state.RigState.LastRigActionError = ""
                local newModel = MakeAnimatableRig.MakeRig(rig):UnwrapOr(function(e)
                    state.RigState.LastRigActionError = e
                end)
                Selection:Set(if newModel then {newModel} else {})
            end)
        end

        Iris.Separator()
        Iris.Text("Mesh Deformation & Beams")
        Iris.SameLine()
        do
            if Iris.Button("Enter Live Update Mode").clicked() then
                state.RigState.LiveEditingRig = rig
            end
            if Iris.Button("Update Once").clicked() then
                ActionHandling.DoRecordedAction("Update Rig Attachments", function()
                    LinkedComponent.UpdateRigAttachments(rig)
                end)
            end
        end
        Iris.End()

        if state.RigState.LastRigActionError ~= "" then
            Iris.Text{
                `{state.RigState.LastRigActionError}`,
                [Iris.Args.Text.Color] = Color3.new(1,0.5,0.5)
            }
        end
    end

end


function _utils()
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


function m.Cycle(state: T.State)
    Iris.Window("Rig", {isOpened = state.WindowStates.Rig})
    if not state.RigState.LiveEditingRig then
        _selectionView(state)
        Iris.Separator()
        _utils()
    else
        LinkedComponent.UpdateRigAttachments(state.RigState.LiveEditingRig)
        if Iris.Button("Exit Live View").clicked() or not game.Workspace:IsAncestorOf(
            state.RigState.LiveEditingRig
        ) then
            state.RigState.LiveEditingRig = nil
        end
    end
    Iris.End()
end


function m.State(): T.RigState
    return {
        LastRigActionError = "",
        LiveEditingRig = nil
    }
end


return m