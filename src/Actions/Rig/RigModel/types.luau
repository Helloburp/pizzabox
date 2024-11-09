local T_LINKED = require(script.Parent.Parent.LinkedComponent.types)
type ActiveRiggedModel = T_LINKED.ActiveRiggedModel


export type RigModel = {
    Model: Model,
    Joint: BasePart,
    Children: {RigModel}
}


export type Rig = {
    Root: RigModel,
    LinkedComponents: ActiveRiggedModel,
}


export type RigNameEvaluation = {
    RigModelsByModelName: {[string]: RigModel},
    RigModelsByJointName: {[string]: RigModel},
}


export type SkeletonVisualization = {
    Highlight: Highlight,
    Parts: {BasePart},
    Model: Model,
}


return {}