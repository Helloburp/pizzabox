local T_RIG = require(script.Parent.Parent.RigModel.types)
type Rig = T_RIG.Rig


export type MorphedRig = {
    Rig: Rig,
    Humanoid: Humanoid,
    Animator: Animator
}

return {}