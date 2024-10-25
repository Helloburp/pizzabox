local T = require(script.Parent.Parent["OC.types"])
local Result = require(script.Parent.Parent.Parent.Result)

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local m = {}

--[[
    The model passed in is the model *within* the root OC part model.
    It is the sibling of the nodes & root node.
]]
function m.GetDefaultAttributes(visualModel: Model): T.ParsedAttributes
    local val = {
        InitialMaterials = {},
        ModelColors = {},
        ModelMaterialColors = {}
    }

    for _, descendant in pairs(visualModel:GetDescendants()) do
        if not descendant:IsA("BasePart") then continue end
        if not table.find(val.ModelMaterialColors, descendant.Color) then
            table.insert(val.InitialMaterials, descendant.Material)
            table.insert(val.ModelMaterialColors, descendant.Color)
            table.insert(val.ModelColors, descendant.Color)
        end
    end

    return val
end


function m.ApplyAttributes(rootModel: Model, attributes: T.ParsedAttributes)
    m.ClearAttributes(rootModel)

    for i = 1, #attributes.InitialMaterials do
        rootModel:SetAttribute(
            `InitialMaterial{i}`, attributes.InitialMaterials[i].Name
        )
        rootModel:SetAttribute(
            `ModelColor{i}`, attributes.ModelColors[i]
        )
        rootModel:SetAttribute(
            `ModelMaterial{i}`, attributes.ModelMaterialColors[i]
        )
    end
end


function m.ClearAttributes(rootModel: Model)
    for attrName in pairs(rootModel:GetAttributes()) do
        if (string.match(attrName, "^InitialMaterial")
            or string.match(attrName, "^ModelColor")
            or string.match(attrName, "^ModelMaterial")
        ) then
            rootModel:SetAttribute(attrName, nil)
        end
    end
end


function m.ParseAttributes(
    rootModel: Model
): Result.Result<T.ParsedAttributes, string>
    local attributes: T.ParsedAttributes = {
        InitialMaterials = {},
        ModelColors = {},
        ModelMaterialColors = {}
    }

    for attrName, value in pairs(rootModel:GetAttributes()) do
        local attr, num = string.match(attrName, "(%a-)(%d+)")
        local numVal = num and tonumber(num) or nil
        if not (attr and num and numVal) then continue end
        if not numVal then continue end

        if attr == "InitialMaterial" then
            if typeof(value) ~= "string" then
                return Result.Err("Malformed InitialMaterial attribute")
            end
            attributes.InitialMaterials[num] =
                Enum.Material[value] :: Enum.Material
        elseif attr == "ModelColor" then
            if typeof(value) ~= "Color3" then
                return Result.Err("Malformed Color attribute")
            end
            attributes.ModelColors[num] = value
        elseif attr == "ModelMaterial" then
            if typeof(value) ~= "Color3" then
                return Result.Err("Malformed Color attribute")
            end
            attributes.ModelMaterialColors[num] = value
        end
    end

    if not (#attributes.InitialMaterials == #attributes.ModelColors and
        #attributes.InitialMaterials == #attributes.ModelMaterialColors) then
        return Result.Err("Malformed attributes.")
    end

    return Result.Ok(attributes)
end


function m.ParseOCPart(rootModel: Instance): Result.Result<T.ParsedOCPart, string>
    if not rootModel:IsA("Model") then
        return Result.Err("Selected instance must be a model.")
    end


    local subModel = rootModel:FindFirstChildWhichIsA("Model")
    if not subModel then
        return Result.Err("OC components must have a child which is a Model.")
    end

    local rootNode = rootModel:FindFirstChildWhichIsA("BasePart")
    if not (rootNode and rootModel.PrimaryPart == rootNode) then
        return Result.Err(`OC components must have a PrimaryPart,\n \z
                            which is a child of the main model.`)
    end

    local attributes, err = m.ParseAttributes(rootModel):Unwrap()
    if not attributes then return Result.Err(err) end

    local nodesFolder = rootModel:FindFirstChild("Nodes")
    if not (nodesFolder and nodesFolder:IsA("Folder")) then
        return Result.Ok{
            RootModel = rootModel,
            RootNode = rootNode,
            VisualModel = subModel,
            Nodes = {},
            Attributes = attributes
        }
    end

    local nodes = {}
    for _, child in pairs(nodesFolder:GetChildren()) do
        if not child:IsA("BasePart") then continue end
        nodes[child.Name] = child
    end

    return Result.Ok{
        RootModel = rootModel,
        RootNode = rootNode,
        VisualModel = subModel,
        NodesFolder = nodesFolder,
        Nodes = nodes,
        Attributes = attributes
    }
end


function m.ParseDataModel(): Result.Result<T.ParsedDataModel, string>
    local dataModules = ReplicatedStorage:FindFirstChild(".OCDataModules")
    if not dataModules then
        return Result.Err("Did not find .OCDataModules in ReplicatedStorage.")
    end

    local testModels = ReplicatedStorage:FindFirstChild(".OCTestModels")
    if not testModels then
        return Result.Err("Did not find .OCTestModels in ReplicatedStorage.")
    end

    local componentObjectShopData = (function()
        local inst = dataModules:FindFirstChild("ObjectShopData")
        return inst and inst:FindFirstChild("Components") or nil
    end)()

    local sortedComponentObjectData = (function()
        local inst = dataModules:FindFirstChild("_ObjData")
        return inst and inst:FindFirstChild("[sorted]Components") or nil
    end)()

    local externalCategoryModule = (function()
        local inst = dataModules:FindFirstChild("ObjectShopData")
        return inst and inst:FindFirstChild("ExternalCategoryLists") or nil
    end)()

    if not (componentObjectShopData
        and sortedComponentObjectData
        and externalCategoryModule) then
        return Result.Err("Malformed OCDataModules.")
    end


    return Result.Ok{
        OCTestModels = testModels,
        OCDataModules = dataModules,
        SortedComponentObjectData = sortedComponentObjectData,
        ComponentObjectShopData = componentObjectShopData,
        ExternalCategoryListsModule = externalCategoryModule
    }
end


function m.CanImplement(
    parsedDataModel: T.ParsedDataModel, input: T.ImplementationInput
): Result.Result<any, string>
    if parsedDataModel.OCTestModels:FindFirstChild(input.Name, true) then
        return Result.Err(`Model with name {input.Name} already exists.`)
    end
    return Result.Ok(true)
end

function m.ParseImplementationDirectories(
    parsedDataModel: T.ParsedDataModel,
    implementationInput: T.ImplementationInput
): Result.Result<T.ParsedImplementationDirectories, string>
    local objDataModule = (function()
        local inst = parsedDataModel.SortedComponentObjectData:FindFirstChild(
            implementationInput.ObjectDataModuleName
        )
        return inst and inst:FindFirstChildWhichIsA("ModuleScript") or nil
    end)()

    local modelFolder = (function()
        local inst = parsedDataModel.OCTestModels:FindFirstChild(
            implementationInput.ObjectDataModuleName
        )
        return (inst and inst:IsA("Folder")) and inst or nil
    end)()

    local shopDataModule = (function()
        local inst = parsedDataModel.ComponentObjectShopData:FindFirstChild(
            implementationInput.ShopDataModuleName
        )
        return (inst and inst:IsA("ModuleScript")) and inst or nil
    end)()

    if not (objDataModule and shopDataModule and modelFolder) then
        return Result.Err(
            `Malformed OCDataModules.{"\n"
            }(obj: {objDataModule}, shop: {shopDataModule}, model: {modelFolder
            })`
        )
    end


    return Result.Ok{
        ModelFolder = modelFolder,
        ShopDataModule = shopDataModule,
        ObjDataModule = objDataModule
    }
end


function m.ParseRecommendationPresetNames(
    parsedDataModel: T.ParsedDataModel
): Result.Result<{string}, string>
    local recommendationModule = (function()
        local inst = parsedDataModel.OCDataModules:FindFirstChild("Presets")
        if not inst then return nil end
        inst = inst:FindFirstChild("Recommendations")
        return (inst and inst:IsA("ModuleScript")) and inst or nil
    end)()

    if not recommendationModule then
        return Result.Err("Unable to find recommendations.")
    end

    local names = {}
    local s, r = pcall(function()
        for name in string.gmatch(
            recommendationModule.Source,
            "(%a-)%w-=%w-require") do
            table.insert(names, name)
        end
    end)

    if not s then
        return Result.Err(`Recommendations could not be accessed: {r}`)
    end

    return Result.Ok(names)
end


return m
