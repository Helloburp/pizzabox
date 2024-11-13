local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local MacroElements = require(script.Parent.IrisMacroElements)
local T = require(script.Parent.Parent["Ui.types"])
local C = require(script.Parent.Parent["Ui.constants"])
local m = {}

local inst_rig_actions = script.Parent.Parent.Actions.Rig
local RigSelection = require(inst_rig_actions.RigSelection)
local NewStandardRig = require(inst_rig_actions.NewStandardRig)

local Selection = game:GetService("Selection")

local LinkedComponent = require(inst_rig_actions.LinkedComponent)
local LinkedParse = require(inst_rig_actions.LinkedComponent.Parse)

local RigModel = require(inst_rig_actions.RigModel)
local RigModelUpdate = require(inst_rig_actions.RigModel.Update)
local RigModelInstantiate = require(inst_rig_actions.RigModel.Instantiate)
local RigModelParse = require(inst_rig_actions.RigModel.Parse)

local MorphedRig = require(inst_rig_actions.MorphedRig)
local MorphedRigParse = require(inst_rig_actions.MorphedRig.Parse)

local Helpers = require(script.Parent.Helpers)
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

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
type RigUiSelectedComponent = T.RigUiSelectedComponent

type RigUiEditingState = T.RigUiEditingState
type Result<T,E> = Result.Result<T,E>


--[[
    Transitions
]]

function _transitionMode(state: RigState, mode: RigUiMode)
    assert(state.UiState._t == "RigEditing")
    if mode._t == "Animated" then
        assert(state.UiState.Mode._t == "Static")
        MorphedRig.BeginAnimationMode(
            state.UiState.RootModel,
            mode.AnimationRigRootModel
        )
        Selection:Set({mode.AnimationRigRootModel})
    elseif mode._t == "Static" then
        assert(state.UiState.Mode._t == "Animated")
        MorphedRig.EndAnimationMode(
            state.UiState.RootModel,
            state.UiState.Mode.AnimationRigRootModel
        )
        state.UiState.Mode.AnimationRigRootModel:Destroy()
        Selection:Set({state.UiState.RootModel})
    end

    state.UiState.Mode = mode
end


function _transitionEditingState(state: RigState, editingState: RigUiEditingState)
    if editingState._t == "NotEditing" then
        assert(state.UiState._t == "RigEditing")
        if state.UiState.Mode._t == "Animated" then
            _transitionMode(state, {_t = "Static", Output = Output.New()})
        end
        state.UiState.WorkingFolder:Destroy()
    elseif editingState._t == "RigEditing" then
        assert(state.UiState._t == "NotEditing")
    end

    state.UiState = editingState
end


--[[
    States
]]

local _animatorMode: (state: RigState) -> RigUiTransition? do

    function _animatorMode(state: RigState): RigUiTransition?
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Animated")
        local myOutput = state.UiState.Mode.Output

        local dt do
            local tic = tick()
            local dtState = Iris.State(tic - 0.0001)
            dt = tic - dtState:get()
            dtState:set(tic)
        end

        local morphedRig = MorphedRigParse.ParseMorphedRig(
            state.UiState.Mode.AnimationRigRootModel
        ):Ok()


        local transition: RigUiTransition? = nil
        
        if morphedRig then
            MorphedRig.StepAnimation(morphedRig, dt)

            Iris.Separator()
            Iris.SameLine()
            do
                local id = Iris.State(0)
                if Iris.Button("Load by ID").clicked() then
                    Helpers.RecordActionToOutputPcall(myOutput, "LOAD_ANIMID", function()
                        MorphedRig.StopAnimations(morphedRig)
                        MorphedRig.LoadId(morphedRig, `rbxassetid://{id:get()}`):Play()
                    end)
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
                local chosenAnim = Iris.State("No Selection")
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
                        local anim = animList[table.find(animNames, chosenAnim:get())]

                        if anim then
                            if anim:IsA("KeyframeSequence") then
                                local id = KeyframeSequenceProvider:RegisterKeyframeSequence(anim)
                                MorphedRig.LoadId(morphedRig, id):Play()
                            else
                                MorphedRig.LoadId(morphedRig, anim.AnimationId):Play()
                            end
                        end
                    end
                end
            end
        else
            local newOutput = Output.New()
            Output.Set(
                newOutput.Warnings, "MODE_TRANSITION",
                "Animation Mode exited unexpectedly, as the Animation Rig \z
                was unable to be validated."
            )
            transition = {
                _t = "Mode",
                Value = { _t = "Static", Output = newOutput }
            }
        end


        if Iris.Button("Exit Animation Mode").clicked() then
            transition = {
                _t = "Mode",
                Value = { _t = "Static", Output = Output.New() }
            }
        end

        MacroElements.OutputText(Output.Format(state.UiState.Mode.Output))

        return transition
    end
end


local _rigMode: (RigState) -> RigUiTransition? do

    local function _rigEditorLiveLinkedComponentUpdateToggle(state: RigState)
        assert(state.UiState._t == "RigEditing")
        if Iris.Checkbox(
            {"Deformation/Beam Preview"},
            {isChecked = state.LiveLinkedComponentUpdatesState}
        ).isChecked:get() then
            LinkedComponent.UpdateRigAttachments(state.UiState.RootModel)
        end
    end

    local function _rigVisualizerToggle(state: RigState, rootRigModel: RigModel?)
        assert(state.UiState._t == "RigEditing")
        if Iris.Checkbox(
            {"Rig Visualizer"},
            {isChecked = state.RigVisualizerState}
        ).isChecked:get() and rootRigModel and not state.LastRigVisualizer then
            local skeleton = RigModelInstantiate.NewSkeletonVisualization(
                rootRigModel, Vector2.new(0.05,0.05)
            )
            skeleton.Model.Parent = state.UiState.WorkingFolder
            state.LastRigVisualizer = skeleton.Model
        end
    end


    local function _animationModeButton(state: RigState, rig: Rig?): RigUiTransition?
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Static")
        if not Iris.Button("Enter Animation Mode").clicked() then return nil end

        local newModel, err = MorphedRig.NewAnimationRig(state.UiState.RootModel):Unwrap()
        if err then
            Output.Set(state.UiState.Mode.Output.Errors, "NEW_ANIM_RIG_ERROR", err)
            return nil
        else
            assert(newModel)

            local newOutput = Output.New()
            Output.Set(newOutput.Notices, "RIG_NOTICE",
                "Animated Rig created. \z
                Your old unrigged model has been placed into ServerStorage."
            )
            return {
                _t = "Mode",
                Value = {
                    _t = "Animated",
                    AnimationRigRootModel = newModel.Rig.Root.Model,
                    Output = newOutput
                }
            }
        end
    end

    local function _primaryParts(state: RigState, rig: Rig?)
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Static")

        local myOutput = state.UiState.Mode.Output

        Iris.Text("Primary Parts")
        Iris.SameLine()
        if Iris.Button("Reset Transparency").clicked() and rig then
            Helpers.RecordActionToOutputPcall(
                myOutput.Errors, "SET_PRIMARYPARTS_VISIBLE",
                function() RigModelUpdate.DisableJointTransparency(rig.Root) end
            )
        end
        if Iris.Button("Set Invisible").clicked() and rig then
            Helpers.RecordActionToOutputPcall(
                myOutput.Errors, "SET_PRIMARYPARTS_INVISIBLE",
                function() RigModelUpdate.MakeJointsInvisible(rig.Root) end
            )
        end
        if Iris.Button("Set Visible").clicked() and rig then
            Helpers.RecordActionToOutputPcall(
                myOutput.Errors, "SET_PRIMARYPARTS_TRANSPARENT",
                function() RigModelUpdate.MakeJointsInvisible(rig.Root, 0.5) end
            )
        end
        Iris.End()
    end


    local function _lod(state: RigState)
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Static")

        local myOutput = state.UiState.Mode.Output
        Iris.Text("Demo LOD")
        Iris.SameLine()
        local function _setLod(level: number)
            RigModelUpdate.SetLevelOfDetailDemo(state.UiState.RootModel, level)
        end

        local function _lodButton(text: string, tooltip: string, _f: () -> ())
            local button = Iris.Button(text)
            if button.clicked() then
                Helpers.RecordActionToOutputPcall(
                    myOutput.Errors, `LOD_{text}`, _f
                )
            end
            if button.hovered() then Iris.Tooltip(tooltip) end
        end

        _lodButton("0", "Disabled",
            function()
                RigModelUpdate.DisableLevelOfDetailDemo(state.UiState.RootModel)
            end
        )
        _lodButton("1", "Least distance",
            function() _setLod(1) end
        )
        _lodButton("2", "Medium distance",
            function() _setLod(2) end
        )
        _lodButton("3", "Most distance",
            function() _setLod(3) end
        )
        Iris.End()
    end


    function _extendRig(state: RigState, rigModel: RigModel): RigModel?
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Static")
        local modelNameInput = Iris.State("")
        local jointNameInput = Iris.State("")
        local sizeInput = Iris.State(false)
        local newModel = nil

        if Iris.Button("Extend Rig").clicked() then
            Helpers.RecordActionToOutputPcall(state.UiState.Mode.Output, "EXTEND_RIG", function()
                newModel = RigModelInstantiate.NewRigModel(
                    modelNameInput:get(),
                    jointNameInput:get(),
                    if sizeInput:get() then 0.124 else 0.4,
                    rigModel.Model:GetPivot()
                )
                newModel.Model.Parent = rigModel.Model
            end)
        end

        Iris.Tree("Options...", {isUncollapsed = true})
        Iris.InputText({"", "Model Name"}, {text = modelNameInput})
        Iris.InputText({"", "PrimaryPart Name"}, {text = jointNameInput})
        Iris.Checkbox({"Small PrimaryPart size?"}, {isChecked = sizeInput})
        Iris.End()

        return newModel
    end


    function _selectionOptions(state: RigState, rig: Rig?)
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Static")

        local myOutput = state.UiState.Mode.Output

        local selectionResult: Result<RigUiSelectedComponent, string> = (function()
            if not rig then return Result.Err("No rig selected!") end
            local selected = Selection:Get()[1]
            if not selected then return Result.Err("Nothing selected!") end
            if not rig.Root.Model:IsAncestorOf(selected) then
                return Result.Err("The selected component must be a descendant of the rig.")
            end

            if selected:IsA("Model") then
                local rigModel = RigModelParse.ContainsModel(rig.Root, selected)
                return if rigModel then Result.Ok{
                    _t = "RigModel",
                    RigModel = rigModel
                } else Result.Err("The selected model is not a valid component of the rig.")
            elseif selected:IsA("BasePart") then
                local rigModel = RigModelParse.ContainsJoint(rig.Root, selected)
                return if rigModel then Result.Ok{
                    _t = "Joint",
                    RigModel = rigModel
                } else Result.Err("The selected part is not a PrimaryPart of the rig.")
            elseif selected:IsA("Bone") then
                return Result.Ok{
                    _t = "Bone",
                    Component = selected
                }
            elseif selected:IsA("Beam") then
                return Result.Ok{
                    _t = "Beam",
                    Component = selected
                }
            end

            return Result.Err("Select a rig component to access more options.")
        end)()

        local selection = selectionResult:Ok()
        if not selection then
            if Iris.Text({
                `No options available for selection. \n({selectionResult:Err()})`,
                [Iris.Args.Text.Wrapped] = true
            }).hovered() then
                Iris.Tooltip("Instances with valid options are: Models, Parts, Bones, and Beams.")
            end
            return
        end

        if not rig then return end

        if selection._t == "RigModel" then
            Iris.Text(`Model Options ({selection.RigModel.Model.Name})`)
            local newModel = _extendRig(state, selection.RigModel)
            if newModel then Selection:Set({newModel.Model}) end

        elseif selection._t == "Joint" then
            Iris.Text(`PrimaryPart Options ({selection.RigModel.Joint.Name})`)
            local newModel = _extendRig(state, selection.RigModel)
            if newModel then Selection:Set({newModel.Joint}) end

        elseif selection._t == "Bone" then
            Iris.Text(`Bone Options ({selection.Component.Name})`)
            if Iris.Button("New Target").clicked() then
                Helpers.RecordActionToOutputPcall(myOutput, "NEW_BONE_TARGET", function()
                    local def, err = LinkedComponent.NewBoneTarget(
                        selection.Component,
                        rig.Root.Model
                    ):Unwrap()
                    if not def then error(err) end
                    local target = LinkedParse.ParseActiveBone(def)
                    Selection:Set({target and target.Target})
                end)
            end

        elseif selection._t == "Beam" then
            Iris.Text(`Beam Options ({selection.Component.Name})`)
            if Iris.Button("New Target").clicked() then
                Helpers.RecordActionToOutputPcall(myOutput, "NEW_BEAM_TARGET", function()
                    local def, err = LinkedComponent.NewBeamTarget(
                        selection.Component,
                        rig.Root.Model
                    ):Unwrap()
                    if not def then error(err) end
                    local target = LinkedParse.ParseActiveBeam(def)
                    Selection:Set({target and target.Target})
                end)
            end
        end
    end


    function _rigMode(state: RigState): RigUiTransition?
        assert(state.UiState._t == "RigEditing")
        assert(state.UiState.Mode._t == "Static")
        local myOutput = state.UiState.Mode.Output

        local transition: RigUiTransition? = nil

        local rig = (function()
            if not game:IsAncestorOf(state.UiState.RootModel) then
                return Result.Err("Rig's parent was set to nil.")
            end
            local rigResult = RigModel.GetRigFromMainRigModel(state.UiState.RootModel)
            local rig = rigResult:Ok()

            if rig then return rig end

            local newOutput = Output.New()
            Output.Set(
                newOutput.Warnings, "MODE_TRANSITION",
                `Editing exited unexpectedly, as the Rig was unable to be validated: "\z
                {rigResult:Err()}"`
            )
            transition = {
                _t = "EditingState",
                Value = {
                    _t = "NotEditing", Output = newOutput
                }
            }

            return nil
        end)()


        local animationTransition = _animationModeButton(state, rig)
        transition = transition or animationTransition
        Iris.Separator()
        Iris.Tree("Rig Settings")
        do
            Iris.Separator()
            _rigEditorLiveLinkedComponentUpdateToggle(state)
            _rigVisualizerToggle(state, rig and rig.Root)
            Iris.Separator()
            _primaryParts(state, rig)
            _lod(state)
        end
        Iris.End()

        Iris.Separator()
        _selectionOptions(state, rig)
        Iris.Separator()

        if Iris.Button("Exit Edit Mode").clicked() then
            transition = {
                _t = "EditingState",
                Value = { _t = "NotEditing", Output = Output.New() }
            }
        end

        local evaluation = RigModelParse.EvaluateRigNames(rig)
        Output.Set(myOutput.Warnings, "RIG_NAME_EVALUATION", evaluation:Err())

        MacroElements.OutputText(Output.Format(myOutput))

        return transition
    end
end


local _editingState: (RigState) -> RigUiTransition? do

    function _editingState(state: RigState): RigUiTransition?
        assert(state.UiState._t == "RigEditing")
        local mode = state.UiState.Mode._t
        local transition = nil
        
        if mode == "Static" then
            transition = _rigMode(state)
        elseif mode == "Animated" then
            transition = _animatorMode(state)
        end

        return transition
    end
end


local _notEditingState: (RigState) -> RigUiTransition? do

    local function _selectionView(state: RigState): {EditButtonClicked: boolean, Rig: Model}?
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
        if not rig then return nil end

        local output = {
            EditButtonClicked = false,
            Rig = selection.Rig
        }

        Iris.Separator()
        if Iris.Button("Enter Edit Mode").clicked() then
            output.EditButtonClicked = true
        end

        return output
    end


    local function _utils(state: RigState)
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


    function _notEditingState(state: RigState): RigUiTransition?
        assert(state.UiState._t == "NotEditing")

        local transition: RigUiTransition? = nil

        local selectionOutput = _selectionView(state)
        Iris.Separator()
        _utils(state)
        Iris.Separator()
        MacroElements.OutputText(Output.Format(state.UiState.Output))

        if selectionOutput and selectionOutput.EditButtonClicked then
            local folder = Instance.new("Folder", selectionOutput.Rig)
            folder.Name = "__pizzabox_working"
            transition = {
                _t = "EditingState",
                Value = {
                    _t = "RigEditing",
                    RootModel = selectionOutput.Rig,
                    WorkingFolder = folder,
                    Mode = {
                        _t = "Static",
                        Output = Output.New(),
                    }
                }
            }
        end

        return transition
    end

end


function m.Cycle(state: State)
    m.CycleCleanup(state.RigState)
    local subWindowName = if state.RigState.UiState._t == "RigEditing"
        then (
            if state.RigState.UiState.Mode._t == "Static"
                then `(Editing {state.RigState.UiState.RootModel.Name})`
                else `(Animating {state.RigState.UiState.RootModel.Name})`
        )
        else ""
    Iris.Window(`Rig {subWindowName}`, {isOpened = state.WindowStates.Rig})
    local rigState = state.RigState
    local uiState = rigState.UiState._t

    local transition =
        if uiState == "NotEditing" then _notEditingState(rigState)
        elseif uiState == "RigEditing" then _editingState(rigState)
        else error(`Invalid state: {uiState}`)
    
    if transition then
        local transitionType = transition._t
        if transitionType == "EditingState" then
            _transitionEditingState(rigState, transition.Value)
        elseif transitionType == "Mode" then
            _transitionMode(rigState, transition.Value)
        end
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
    if state.UiState._t == "RigEditing" then
        _transitionEditingState(state, {
            _t = "NotEditing",
            Output = Output.New()
        })
    end
end


function m.State(): RigState
    return {
        RigVisualizerState = Iris.State(false),
        LiveLinkedComponentUpdatesState = Iris.State(true),
        AnimationPlayingState = Iris.State(false),
        UiState = {
            _t = "NotEditing",
            Output = Output.New()
        },
    }
end


return m