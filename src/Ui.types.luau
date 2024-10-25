type IrisState<T> = any

export type State = {
    PluginOpenState: IrisState<boolean>,
    
    SubMenuStates: {
        Rig: IrisState<boolean>,
        OC: IrisState<boolean>,
    },

    Settings: {
        Theme: IrisState<string>
    },

    LastRigActionError: string
}

return {}