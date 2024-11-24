local inst_root = script.Parent.Parent.Parent.Parent
local Output = require(inst_root.Ui.Output)
local T = require(inst_root["Ui.types"])
local C = require(inst_root["Ui.constants"])

type RigUiEditingState = T.RigUiEditingState

local MorphEffectsController = require(inst_root.TprrMorphLib.MorphEffects)
type MorphEffectsController = MorphEffectsController.MorphEffectsController

local inst_morphed_rig = inst_root.Actions.Rig.MorphedRig
local MorphedRig = {
    Parse = require(inst_morphed_rig.Parse)
}

local T_MORPHEDRIG = require(inst_root.Actions.Rig.MorphedRig.types)
type MorphedRig = T_MORPHEDRIG.MorphedRig

local ServerStorage = game:GetService("ServerStorage")


local m = {}


function m.NewWorkingFolder(parent: Instance): Folder
    local folder = Instance.new("Folder", parent)
    folder.Name = "__pizzabox_working"
    return folder
end


function m.NewRigEditingState(rootRigModel: Model): RigUiEditingState
    return {
        _t = "RigEditing",
        Output = Output.New(),
        RootModel = rootRigModel,
        WorkingFolder = m.NewWorkingFolder(rootRigModel)
    }
end

function m.NewRigAnimatingState(
    animatingRig: Model, rootRigModel: Model?, shakeEnabledState: any
): RigUiEditingState
    local morphedRig = MorphedRig.Parse.ParseMorphedRig(animatingRig):Ok()
    local soundLibrary = _getSoundLibrary()
    local output = Output.New()

    Output.Set(output.Warnings, "SOUND_LIBRARY", if not soundLibrary
        then "Unable to find ServerStorage.AnimatronicData.AnimationSounds. \z
            Keyframe Event sound previews will be unavailable."
        else nil
    )

    return {
        _t = "RigAnimating",
        Output = output,
        BaseRootModel = rootRigModel,
        AnimationRigRootModel = animatingRig,
        MorphEffectsController = if morphedRig
            then MorphEffectsController.NewMorphEffectsController(
                morphedRig.Rig.Root.Model,
                morphedRig.Rig.Root.Joint,
                morphedRig.Animator,
                soundLibrary or script,
                function(...)
                    if not shakeEnabledState:get() then return nil end
                    return C.SHAKE_CALLBACK(...)
                end,
                C.GET_SOUND_PARENT()
            )
            else {
                Update = function() end,
                Cleanup = function() end
            },
        WorkingFolder = m.NewWorkingFolder(animatingRig)
    }
end


function m.NewMultiSelectState(modelRoots: {Model}): RigUiEditingState
    return {
        _t = "MultiSelect",
        RigRootModels = modelRoots
    }
end


function m.NewNotEditingState(): RigUiEditingState
    return {
        _t = "NotEditing",
        Output = Output.New()
    }
end


function _getSoundLibrary(): Instance?
    local animatronicData = ServerStorage:FindFirstChild("AnimatronicData")
    if not animatronicData then return nil end
    return animatronicData:FindFirstChild("AnimationSounds")
end


return m