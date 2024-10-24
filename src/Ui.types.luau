type IrisState<T> = any

export type State = {
    PluginOpenState: IrisState<boolean>,
    
    SubMenuStates: {
        Rig: IrisState<boolean>,
    },

    LastRigActionError: IrisState<string>
}

return {}