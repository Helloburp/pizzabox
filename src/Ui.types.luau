local T_RIGMODEL = require(script.Parent.Actions.Rig.RigModel.types)
type RigModel = T_RIGMODEL.RigModel

local MorphEffects = require(script.Parent.TprrMorphLib.MorphEffects)
type MorphEffectsController = MorphEffects.MorphEffectsController


type IrisState<T> = any

export type TaggedText = { Id: string, Text: string }


export type ActionOutput = {
    Errors: { TaggedText },
    Warnings: { TaggedText },
    Notices: { TaggedText }
}

export type OcState = {
    ImplementAsNew: IrisState<boolean>,
    FazCoinCost: IrisState<number>,
    ObjDataModuleName: IrisState<string>,
    ShopDataModuleName: IrisState<string>,
    RecommendationPresetName: IrisState<string>,
    LastImplementationError: string,
    UsingRecommendationPresetName: IrisState<boolean>
}


export type RigUiSelectedComponent = {
    _t: "Bone",
    Component: Bone
} | {
    _t: "Beam",
    Component: Beam
} | {
    _t: "RigModel",
    RigModel: RigModel
} | {
    _t: "Joint",
    RigModel: RigModel
}

export type RigUiEditingState = {
    _t: "NotEditing",
    Output: ActionOutput
} | {
    _t: "RigEditing",
    RootModel: Model,
    WorkingFolder: Folder,
    SelectedComponent: RigUiSelectedComponent?,
    Output: ActionOutput
} | {
    _t: "RigAnimating",
    BaseRootModel: Model?,
    AnimationRigRootModel: Model,
    MorphEffectsController: MorphEffectsController,
    WorkingFolder: Folder,
    Output: ActionOutput
} | {
    _t: "MultiSelect",
    RigRootModels: {Model},
}


export type RigState = {
    LastRigVisualizer: Instance?,
    RigVisualizerState: IrisState<boolean>,
    LiveLinkedComponentUpdatesState: IrisState<boolean>,
    CamShakeEnabledState: IrisState<boolean>,
    UiState: RigUiEditingState
}

export type State = {
    Plugin: Plugin,
    PluginOpenState: IrisState<boolean>,
    
    WindowStates: {
        Rig: IrisState<boolean>,
        OC: IrisState<boolean>,
    },

    Settings: {
        Theme: IrisState<string>
    },

    OcState: OcState,
    RigState: RigState,
}

return {}