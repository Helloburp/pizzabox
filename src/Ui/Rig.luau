local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local T = require(script.Parent.Parent["Ui.types"])
local m = {}

local inst_rig_actions = script.Parent.Parent.Actions.Rig
local RigSelection = require(inst_rig_actions.RigSelection)
local MakeAnimatableRig = require(inst_rig_actions.MakeAnimatableRig)
local NewStandardRig = require(inst_rig_actions.NewStandardRig)
local Selection = game:GetService("Selection")

local ActionHandling = require(script.Parent.ActionHandling)



function _selectionView(state: T.State)
    local selection, err = RigSelection.Parse():Unwrap()

    local textArgs = if selection and selection.Joints then {
            `Rig and Joints Selected: {selection.Rig.Name}, {selection.Joints.Name}`,
            [Iris.Args.Text.Color] = Color3.new(0, 1 ,0.5)
        } elseif selection and not selection.Joints then {
            `Rig selected: {selection.Rig.Name}`,
            [Iris.Args.Text.Color] = Color3.new(0, 1 ,0.5)
        } else {
            err or "No rig selected.",
            [Iris.Args.Text.Color] = Color3.new(1, 0.5 ,0.5)
        }

    Iris.Text(textArgs)

    local rig, joints =
        selection and selection.Rig,
        selection and selection.Joints

    if rig and Iris.Button("Make Animatable Rig").clicked() then
        ActionHandling.DoRecordedAction("Make Rig", function()
            state.LastRigActionError = ""
            local newModel = MakeAnimatableRig.MakeRig(rig):UnwrapOr(function(e)
                state.LastRigActionError = e
            end)
            Selection:Set(if newModel then {newModel} else {})
        end)
    end

    if state.LastRigActionError ~= "" then
        Iris.Text{
            `{state.LastRigActionError}`,
            [Iris.Args.Text.Color] = Color3.new(1,0.5,0.5)
        }
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
    Iris.Window("Rig", {isOpened = state.SubMenuStates.Rig})
    _utils()
    Iris.Separator()
    _selectionView(state)
    Iris.End()
end


return m