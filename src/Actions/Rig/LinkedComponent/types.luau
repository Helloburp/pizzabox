export type TargetDefinition = ObjectValue | StringValue

export type BoneDefinition = LinkDefinition<Bone>
export type ActiveBone = ActiveLink<Bone, PVInstance> & {
    Children: {ActiveBone}
}

export type BeamDefinition = LinkDefinition<Beam>
export type ActiveBeam = ActiveLink<Beam,Attachment>

export type ActiveRiggedModel = {
    Beams: {ActiveBeam},
    AncestorBones: {ActiveBone},
    Model: Model,
}

export type LinkDefinition<I> = {
	Component: I,
	Target: TargetDefinition,
    RootModel: Model
}

export type ActiveLink<I,T> = {
    Component: I,
    Target: T
}

return {}