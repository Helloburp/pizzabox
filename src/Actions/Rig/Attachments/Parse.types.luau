
export type BoneDefinition = {
	Bone: Bone,
	Target: ObjectValue | StringValue,
	RootModel: Model,
}

export type ActiveBone = {
	Bone: Bone,
	Target: PVInstance,
    Children: {ActiveBone}
}

export type BeamDefinition = {
	Beam: Beam,
	Target: ObjectValue | StringValue,
    RootModel: Model
}

export type ActiveBeam = {
    Beam: Beam,
    Target: Attachment
}


export type ActiveRiggedModel = {
    Beams: {ActiveBeam},
    AncestorBones: {ActiveBone},
    Model: Model,
    RootModel: Model,
}

return {}