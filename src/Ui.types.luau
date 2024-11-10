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


export type RigUiMode = {
    _t: "Static",
    SelectedComponent: {
        _t: "Bone",
        Component: Bone
    } | {
        _t: "Beam",
        Component: Beam
    }?,
    Output: ActionOutput
} | {
    _t: "Animated",
    AnimationRigRootModel: Model
}


export type RigUiEditingState = {
    _t: "NotEditing",
    Output: ActionOutput
} | {
    _t: "RigEditing",
    RootModel: Model,
    Mode: RigUiMode
} 


export type RigUiTransition = {
    _t: "Mode",
    Value: RigUiMode,
} | {
    _t: "EditingState",
    Value: RigUiEditingState
}


export type RigState = {
    RigVisualizerState: IrisState<boolean>,
    LiveLinkedComponentUpdatesState: IrisState<boolean>,
    AnimationPlayingState: IrisState<boolean>,
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