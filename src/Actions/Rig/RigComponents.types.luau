local T_LINKED = require(script.Parent.Attachments["Parse.types"])
type ActiveRiggedModel = T_LINKED.ActiveRiggedModel


export type RigModel = {
    Model: Model,
    Joint: BasePart,
    Children: {RigModel}
}


export type Rig = {
    Root: RigModel
}


return {}