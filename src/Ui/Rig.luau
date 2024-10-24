local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local T = require(script.Parent.Parent["Ui.types"])
local m = {}

local inst_actions = script.Parent.Parent.Actions
local RigSelection = require(inst_actions.RigSelection)
local MakeAnimatableRig = require(inst_actions.MakeAnimatableRig)
local MakeTprrRig = require(inst_actions.MakeTprrRig)
local Selection = game:GetService("Selection")

local ChangeHistoryService = game:GetService("ChangeHistoryService")


function _doRecordedAction(name: string, _f: () -> ())
    local isRecording = ChangeHistoryService:TryBeginRecording(name)
    assert(
        isRecording,
        [[PLUGIN ERROR: Attempted to start a recording before \
            another one was finished.]]
    )
    local s, e = pcall(_f)
    ChangeHistoryService:FinishRecording(
        isRecording,
        if s then Enum.FinishRecordingOperation.Commit
            else Enum.FinishRecordingOperation.Cancel
    )

    if not s then
        warn(`Plugin action '{name}' had an error during execution:\n{e}`)
    end
end


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
        _doRecordedAction("Make Rig", function()
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


function m.Cycle(state: T.State)
    Iris.Window("Rig", {isOpened = state.SubMenuStates.Rig})
    _selectionView(state)
    Iris.End()
end


return m