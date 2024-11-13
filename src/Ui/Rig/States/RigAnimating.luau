local inst_rig_actions = script.Parent.Parent.Parent.Parent.Actions.Rig

local MorphedRig = setmetatable({
    Parse = require(inst_rig_actions.MorphedRig.Parse)
}, {__index = require(inst_rig_actions.MorphedRig)})

local inst_root = script.Parent.Parent.Parent.Parent
local Output = require(inst_root.Ui.Output)
local Iris = require(inst_root.Parent.Packages.Iris)
local MacroElements = require(inst_root.Ui.IrisMacroElements)
local Helpers = require(inst_root.Ui.Helpers)

local LinkedComponent = require(inst_rig_actions.LinkedComponent)

local T = require(inst_root["Ui.types"])
type RigState = T.RigState
type RigUiEditingState = T.RigUiEditingState

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Instantiate = require(script.Parent.Instantiate)


local m = {}


function m.AnimatorMode(state: RigState): RigUiEditingState?
    assert(state.UiState._t == "RigAnimating")
    local myOutput = state.UiState.Output

    local dt do
        local tic = tick()
        local dtState = Iris.State(tic - 0.0001)
        dt = tic - dtState:get()
        dtState:set(tic)
    end

    local morphedRig = MorphedRig.Parse.ParseMorphedRig(
        state.UiState.AnimationRigRootModel
    ):Ok()


    local transition: RigUiEditingState? = nil

    local isPlaying = Iris.State(false)
    local chosenAnim = Iris.State("No Selection")

    if morphedRig then

        Iris.Separator()
        Iris.SameLine()
        do
            local id = Iris.State(0)
            if Iris.Button("Load by ID").clicked() then
                Helpers.RecordActionToOutputPcall(myOutput, "LOAD_ANIMID", function()
                    MorphedRig.StopAnimations(morphedRig)
                    MorphedRig.LoadId(morphedRig, `rbxassetid://{id:get()}`):Play()
                end)
                isPlaying:set(true)
            end
            Iris.InputNum({0, [Iris.Args.InputNum.NoButtons] = true}, {number = id})
        end
        Iris.End()
        Iris.Separator()

        local animList = Helpers.TestAnims()
        if not animList then
            Iris.Text("There is no PIZZABOX_TESTANIMS model in ServerStorage.")
            if Iris.Button("Create One").clicked() then
                Helpers.NewTestAnims()
            end
        elseif #animList == 0 then
            Iris.Text({
                "No KeyframeSequences found in ServerStorage.PIZZABOX_TESTANIMS.",
                [Iris.Args.Text.Wrapped] = true
            })
        else
            local animNames = {}
            for _, v in pairs(animList) do
                if table.find(animNames, v.Name) then continue end
                table.insert(animNames, v.Name)
            end
            table.insert(animNames, "No Selection")
            local combo = Iris.ComboArray({"Animation"}, {index = chosenAnim}, animNames)
            if combo.hovered() then
                Iris.Tooltip(
                    "You can add more Animations or KeyframeSequences in \z
                    ServerStorage.PIZZABOX_TESTANIMS"
                )
            end
            if combo.closed() then
                MorphedRig.StopAnimations(morphedRig)
                if chosenAnim:get() ~= "No Selection" then
                    isPlaying:set(true)
                    local anim = animList[table.find(animNames, chosenAnim:get())]

                    if anim then
                        if anim:IsA("KeyframeSequence") then
                            local id = KeyframeSequenceProvider:RegisterKeyframeSequence(anim)
                            MorphedRig.LoadId(morphedRig, id):Play()
                        else
                            MorphedRig.LoadId(morphedRig, anim.AnimationId):Play()
                        end
                    end
                else
                    isPlaying:set(false)
                end
            end
        end

        if isPlaying:get() then
            if Iris.Button("Stop Animation").clicked() then
                MorphedRig.StopAnimations(morphedRig)
                isPlaying:set(false)
                chosenAnim:set("No Selection")
            end
            MorphedRig.StepAnimation(morphedRig, dt)
        else
            LinkedComponent.UpdateRigAttachments(morphedRig.Rig.Root.Model)
        end
    else
        local newTransition = if state.UiState.BaseRootModel
            then Instantiate.NewRigEditingState(state.UiState.BaseRootModel)
            else Instantiate.NewNotEditingState()
        
        Output.Set(
            newTransition.Output.Warnings, "MODE_TRANSITION",
            "Animation Mode exited unexpectedly, as the Animation Rig \z
            was unable to be validated."
        )

        transition = newTransition
    end

    Iris.Separator()

    if Iris.Button("Exit Animation Mode").clicked() then
        transition = if state.UiState.BaseRootModel
            then Instantiate.NewRigEditingState(state.UiState.BaseRootModel)
            else Instantiate.NewNotEditingState()
    end

    MacroElements.OutputText(Output.Format(state.UiState.Output))

    return transition
end

return m