type IrisState<T> = any

export type OcState = {
    ImplementAsNew: IrisState<boolean>,
    FazCoinCost: IrisState<number>,
    ObjDataModuleName: IrisState<string>,
    ShopDataModuleName: IrisState<string>,
    RecommendationPresetName: IrisState<string>,
    LastImplementationError: string,
    UsingRecommendationPresetName: IrisState<boolean>
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


    LastRigActionError: string
}

return {}