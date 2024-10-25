export type ECommonType =
    "Eye" | "Feet" | "Hands" | "Head" | "Lower Arms" | "Lower Legs" | "Misc" |
    "Torso" | "Upper Arms" | "Upper Legs"

export type EModelType = ECommonType | "Universal"

export type EShopType = ECommonType | "Ears"

export type EShopCategories =
        "Accessories" | "Ears" | "Eyes" | "Heads" | "LeftFeet" | "LeftHands" |
        "LowerLeftArms" | "LowerLeftLegs" | "LowerRightArms" |
        "LowerRightLegs" | "RightFeet" | "RightHands" | "Torsos" |
        "UpperLeftArms" | "UpperLeftLegs" | "UpperRightArms" | "UpperRightLegs"

export type ParsedOCPart = {
    RootModel: Model,
    RootNode: BasePart,
    VisualModel: Model,
    NodesFolder: Folder?,
    Nodes: {BasePart},
    Attributes: ParsedAttributes,
}

export type ParsedAttributes = {
    InitialMaterials: {Enum.Material},
    ModelColors: {Color3},
    ModelMaterialColors: {Color3}
}

export type ParsedDataModel = {
    OCTestModels: Folder,
    OCDataModules: Folder,
    ComponentObjectShopData: Folder,
    SortedComponentObjectData: Folder,
    ExternalCategoryListsModule: ModuleScript,
}

export type ParsedImplementationDirectories = {
    ModelFolder: Folder,
    ObjDataModule: ModuleScript,
    ShopDataModule: ModuleScript,
}

export type ImplementationDetails = {
    Directories: ParsedImplementationDirectories,
    ObjDataLineNumber: number,
    ShopDataLineNumber: number,
    ExternalCategoryLineNumber: number?,
}

export type ImplementationInput = {
    ShopDataModuleName: EShopType,
    ObjectDataModuleName: EModelType,
    RecommendationPresetName: string?,
    Categories: {EShopCategories},
    ImplementAsNew: boolean,
    FazCoinCost: number,
    Name: string,
    Model: Model

}

return {}