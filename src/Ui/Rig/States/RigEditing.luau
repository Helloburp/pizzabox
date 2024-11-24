
local inst_rig_actions = script.Parent.Parent.Parent.Parent.Actions.Rig

local RigModel = setmetatable({
    Parse = require(inst_rig_actions.RigModel.Parse),
    Instantiate = require(inst_rig_actions.RigModel.Instantiate),
    Update = require(inst_rig_actions.RigModel.Update)
}, {__index = require(inst_rig_actions.RigModel)})

local T_RIGMODEL = require(inst_rig_actions.RigModel.types)
type RigModel = T_RIGMODEL.RigModel
type Rig = T_RIGMODEL.Rig

local MorphedRig = require(inst_rig_actions.MorphedRig)

local LinkedComponent = setmetatable(
    {
        Parse = require(inst_rig_actions.LinkedComponent.Parse)
    },
    {__index = require(inst_rig_actions.LinkedComponent)}
)

local CollisionOverride = {
    Instantiate = require(inst_rig_actions.CollisionOverride.Instantiate),
    Parse = require(inst_rig_actions.CollisionOverride.Parse),
    Update = require(inst_rig_actions.CollisionOverride.Update),
}

local inst_root = script.Parent.Parent.Parent.Parent
local Output = require(inst_root.Ui.Output)
local Iris = require(inst_root.Parent.Packages.Iris)
local MacroElements = require(inst_root.Ui.IrisMacroElements)
local Helpers = require(inst_root.Ui.Helpers)
local Result = require(inst_root.Result)
type Result<T,E> = Result.Result<T,E>

local Selection = game:GetService("Selection")
local Instantiate = require(script.Parent.Instantiate)

local T = require(inst_root["Ui.types"])
type RigState = T.RigState
type RigUiEditingState = T.RigUiEditingState
type RigUiSelectedComponent = T.RigUiSelectedComponent


local m = {}


function m.RigMode(state: RigState): RigUiEditingState?
    assert(state.UiState._t == "RigEditing")
    local myOutput = state.UiState.Output

    local transition: RigUiEditingState? = nil

    local rig: Rig? = (function()
        if not game:IsAncestorOf(state.UiState.RootModel) then
            return Result.Err("Rig's parent was set to nil.")
        end
        local rigResult = RigModel.GetRigFromMainRigModel(state.UiState.RootModel)
        local rig = rigResult:Ok()

        if rig then return rig end

        local newTransition = Instantiate.NewNotEditingState()
        Output.Set(
            newTransition.Output.Warnings, "MODE_TRANSITION",
            `Editing exited unexpectedly, as the Rig was unable to be validated: "\z
            {rigResult:Err()}"`
        )

        transition = newTransition

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
    _collisionFixWidget(state, rig and rig.Root)
    Iris.Separator()

    if Iris.Button("Exit Edit Mode").clicked() then
        transition = Instantiate.NewNotEditingState()
    end

    if rig then
        local evaluation = RigModel.Parse.EvaluateRigNames(rig)
        Output.Set(myOutput.Warnings, "RIG_NAME_EVALUATION", evaluation:Err())

        local boneEvaluation = LinkedComponent.Parse.EvaluateBoneNames(rig.Root.Model)
        Output.Set(myOutput.Warnings, "BONE_NAME_EVALUATION", boneEvaluation:Err())
    end

    MacroElements.OutputText(Output.Format(myOutput))

    return transition
end


function _collisionFixWidget(state: RigState, rootRigModel: RigModel?)
    assert(state.UiState._t == "RigEditing")
    if not rootRigModel then
        Output.Set(state.UiState.Output.Notices, "COLLISION_FIX", nil)
        return
    end

    local lowerTorso = RigModel.Parse.ContainsModelWithName(rootRigModel, "LowerTorso")
    if not lowerTorso then
        Output.Set(state.UiState.Output.Notices, "COLLISION_FIX",
            `Rig does not have a LowerTorso, so Collision Overriding is not available.`
        )
        return
    end
    Output.Set(state.UiState.Output.Notices, "COLLISION_FIX", nil)

    local currentValidScript = CollisionOverride.Parse.ParseValidScript(lowerTorso.Model):Ok()
    local lastSettings = (function()
        local lastScript = CollisionOverride.Parse.GetExistingScripts(lowerTorso.Model)[1]
        return lastScript
            and CollisionOverride.Parse.GetSettings(lastScript)
            or {} :: {[Enum.BodyPartR15]: boolean}
    end)()

    if not currentValidScript then
        if Iris.Button("Add Collision Override Script").clicked() then

            Helpers.RecordActionToOutputPcall(state.UiState.Output.Errors, "COLLISION_FIX",
                function()
                    CollisionOverride.Instantiate.Clear(lowerTorso.Model)
                    local newScript = CollisionOverride.Instantiate.New(lowerTorso.Model)
                    CollisionOverride.Update.UpdateSettings(newScript, lastSettings)
                end
            )
        end
        return
    else
        local states = {}
        for _, enumItem: Enum.BodyPartR15 in pairs(Enum.BodyPartR15:GetEnumItems()) do
            states[enumItem] = Iris.State(lastSettings[enumItem])
        end

        Iris.Tree("Remove Collision From...")
        Iris.Table(3)
        for _, enumItem: Enum.BodyPartR15 in pairs(Enum.BodyPartR15:GetEnumItems()) do
            if enumItem.Name == "Unknown" or enumItem.Name == "RootPart" then continue end
            Iris.Checkbox(enumItem.Name, {isChecked = states[enumItem]})
            Iris.NextColumn()
        end
        Iris.End()
        if Iris.Button("Delete Collision Override Script").clicked() then

            Helpers.RecordActionToOutputPcall(state.UiState.Output.Errors, "COLLISION_FIX",
                function() currentValidScript.Parent = nil end
            )
        end

        Iris.End()

        local newSettings = {}
        for enumItem, state in pairs(states) do
            newSettings[enumItem] = state:get()
        end

        CollisionOverride.Update.UpdateSettings(currentValidScript, newSettings)
    end

end


function _rigEditorLiveLinkedComponentUpdateToggle(state: RigState)
    assert(state.UiState._t == "RigEditing")
    if Iris.Checkbox(
        {"Deformation/Beam Preview"},
        {isChecked = state.LiveLinkedComponentUpdatesState}
    ).isChecked:get() then
        LinkedComponent.UpdateRigAttachments(state.UiState.RootModel)
    end
end


function _rigVisualizerToggle(state: RigState, rootRigModel: RigModel?)
    assert(state.UiState._t == "RigEditing")
    if Iris.Checkbox(
        {"Rig Visualizer"},
        {isChecked = state.RigVisualizerState}
    ).isChecked:get() and rootRigModel and not state.LastRigVisualizer then
        local skeleton = RigModel.Instantiate.NewSkeletonVisualization(
            rootRigModel, Vector2.new(0.05,0.05)
        )
        skeleton.Model.Parent = state.UiState.WorkingFolder
        state.LastRigVisualizer = skeleton.Model
    end
end


function _animationModeButton(state: RigState, rig: Rig?): RigUiEditingState?
    assert(state.UiState._t == "RigEditing")
    if not Iris.Button("Enter Animation Mode").clicked() then return nil end

    local myOutput = state.UiState.Output
    local newModel, err = MorphedRig.NewAnimationRig(state.UiState.RootModel):Unwrap()
    if err then
        Output.Set(myOutput.Errors, "NEW_ANIM_RIG_ERROR", err)
        return nil
    else
        assert(newModel)

        local transition = Instantiate.NewRigAnimatingState(
            newModel.Rig.Root.Model, state.UiState.RootModel, state.CamShakeEnabledState
        )
        Output.Set(transition.Output.Notices, "RIG_NOTICE",
            "Animated Rig created. \z
            Your old unrigged model has been placed into ServerStorage."
        )

        return transition
    end
end


function _primaryParts(state: RigState, rig: Rig?)
    assert(state.UiState._t == "RigEditing")

    local myOutput = state.UiState.Output

    Iris.Text("Primary Parts")
    Iris.SameLine()
    if Iris.Button("Reset Transparency").clicked() and rig then
        Helpers.RecordActionToOutputPcall(
            myOutput.Errors, "SET_PRIMARYPARTS_VISIBLE",
            function() RigModel.Update.DisableJointTransparency(rig.Root) end
        )
    end
    if Iris.Button("Set Invisible").clicked() and rig then
        Helpers.RecordActionToOutputPcall(
            myOutput.Errors, "SET_PRIMARYPARTS_INVISIBLE",
            function() RigModel.Update.MakeJointsInvisible(rig.Root) end
        )
    end
    if Iris.Button("Set Visible").clicked() and rig then
        Helpers.RecordActionToOutputPcall(
            myOutput.Errors, "SET_PRIMARYPARTS_TRANSPARENT",
            function() RigModel.Update.MakeJointsInvisible(rig.Root, 0.5) end
        )
    end
    Iris.End()
end


function _lod(state: RigState)
    assert(state.UiState._t == "RigEditing")

    local myOutput = state.UiState.Output
    Iris.Text("Demo LOD")
    Iris.SameLine()
    local function _setLod(level: number)
        RigModel.Update.SetLevelOfDetailDemo(state.UiState.RootModel, level)
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
            RigModel.Update.DisableLevelOfDetailDemo(state.UiState.RootModel)
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
    local modelNameInput = Iris.State("")
    local jointNameInput = Iris.State("")
    local sizeInput = Iris.State(false)
    local newModel = nil
    local myOutput = state.UiState.Output

    if Iris.Button("Extend Rig").clicked() then
        Helpers.RecordActionToOutputPcall(myOutput.Errors, "EXTEND_RIG", function()
            newModel = RigModel.Instantiate.NewRigModel(
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

    local myOutput = state.UiState.Output

    local selectionResult: Result<RigUiSelectedComponent, string> = (function()
        if not rig then return Result.Err("No rig selected!") end
        local selected = Selection:Get()[1]
        if not selected then return Result.Err("Nothing selected!") end
        if not rig.Root.Model:IsAncestorOf(selected) then
            return Result.Err("The selected component must be a descendant of the rig.")
        end

        if selected:IsA("Model") then
            local rigModel = RigModel.Parse.ContainsModel(rig.Root, selected)
            return if rigModel then Result.Ok{
                _t = "RigModel",
                RigModel = rigModel
            } else Result.Err("The selected model is not a valid component of the rig.")
        elseif selected:IsA("BasePart") then
            local rigModel = RigModel.Parse.ContainsJoint(rig.Root, selected)
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
        Iris.Text(`New Bone Target ({selection.Component.Name})`)
        Iris.SameLine()
        if Iris.Button("Part").clicked() then
            Helpers.RecordActionToOutputPcall(myOutput, "NEW_BONE_TARGET", function()
                local def, err = LinkedComponent.NewBoneTarget(
                    selection.Component,
                    rig.Root.Model
                ):Unwrap()
                if not def then error(err) end
                local target = LinkedComponent.Parse.ParseActiveBone(def)
                Selection:Set({target and target.Target})
            end)
        end
        if Iris.Button("Model").clicked() then
            Helpers.RecordActionToOutputPcall(myOutput, "NEW_BONE_TARGET_MODEL", function()
                local def, err = LinkedComponent.NewBoneModel(
                    selection.Component,
                    rig.Root.Model
                ):Unwrap()
                if not def then error(err) end
                local target = LinkedComponent.Parse.ParseActiveBone(def)
                Selection:Set({target and target.Target})
            end)
        end
        if Iris.Button("Model(s) (Recursive)").clicked() then
            Helpers.RecordActionToOutputPcall(
                myOutput,
                "NEW_BONE_TARGET_MODEL_RECURSIVE",
                function()
                    local result, rigModel = LinkedComponent.NewBoneModelRecursive(
                        selection.Component,
                        rig.Root.Model
                    )
                    local def, err = result:Unwrap()
                    if not def then error(err) end
                    assert(rigModel, "Returned result, but not rig model.")

                    Selection:Set({rigModel.Model})
                end
            )
        end
        Iris.End()

    elseif selection._t == "Beam" then
        Iris.Text(`Beam Options ({selection.Component.Name})`)
        if Iris.Button("New Target").clicked() then
            Helpers.RecordActionToOutputPcall(myOutput, "NEW_BEAM_TARGET", function()
                local def, err = LinkedComponent.NewBeamTarget(
                    selection.Component,
                    rig.Root.Model
                ):Unwrap()
                if not def then error(err) end
                local target = LinkedComponent.Parse.ParseActiveBeam(def)
                Selection:Set({target and target.Target})
            end)
        end
    end
end


return m