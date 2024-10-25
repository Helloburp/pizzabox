local T = require(script.Parent["OC.types"])
local m = {}

local Parse = require(script.Parse)
local Result = require(script.Parent.Parent.Result)


function m.Node(parent: Instance, cf: CFrame): BasePart
    local p = Instance.new("Part", parent)
    p.Size = Vector3.new(0.2,0.2,0.2)
    p.Color = Color3.new(1, 0, 0)
    p.Transparency = 0.5
    p.Material = Enum.Material.Plastic
    p.Name = "RootNode"
    p.Anchored = true
    p.CFrame = cf

    local decal = Instance.new("Decal", p)
    decal.Face = Enum.NormalId.Front
    decal.Texture = "rbxassetid://8744022338"

    return p
end

function m.NewOcPartFromModel(
    visualModel: Model
): T.ParsedOCPart
    local rootModel = Instance.new("Model", visualModel.Parent)
    visualModel.Parent = rootModel

    rootModel.Name = visualModel.Name
    visualModel.Name = "Model"

    local nodesFolder = Instance.new("Folder", rootModel)
    nodesFolder.Name = "Nodes"
    
    local rootNode = m.Node(rootModel, visualModel:GetPivot())
    rootNode.Name = "RootNode"
    rootModel.PrimaryPart = rootNode

    local parsedOc = Parse.ParseOCPart(rootModel):Expect(
        "Critical error! New OC component logic is invalid!!"
    )

    return parsedOc
end


function m.ApplyAttributesFromModel(rootModel: Model, visualModel: Model)
    Parse.ApplyAttributes(rootModel, Parse.GetDefaultAttributes(visualModel))
end

function m.ImplementOcPart(
    parsedDataModel: T.ParsedDataModel,
    implInput: T.ImplementationInput
): Result.Result<T.ImplementationDetails, string>
    local implDirs, e_impl = Parse.ParseImplementationDirectories(
        parsedDataModel, implInput
    ):Unwrap()
    if not implDirs then return Result.Err(e_impl) end

    local canImplement, canImplementError = Parse.CanImplement(
        parsedDataModel, implInput
    ):Unwrap()

    if not canImplement then
        return Result.Err(canImplementError)
    end

    implInput.Model.Name = implInput.Name
    implInput.Model.Parent = implDirs.ModelFolder

    local s_read, shopDataSource, objDataSource, externalCategorySource =
        pcall(function()
            return
                implDirs.ShopDataModule.Source,
                implDirs.ObjDataModule.Source,
                parsedDataModel.ExternalCategoryListsModule.Source
        end)

    if not s_read then return Result.Err(shopDataSource) end

    local newObjDataSource, newShopDataSource =
        _getSourceAfterAddOcPartToObjData(
            objDataSource, implInput.Name, implInput.RecommendationPresetName
        ),
        _getSourceAfterAddOcPartToShopModule(
            shopDataSource,
            implInput.Name,
            implInput.FazCoinCost,
            implInput.Categories
        )
    
    local externalCategoryLineNumber = nil
    local s_write, e_write = pcall(function()
        implDirs.ShopDataModule.Source = newShopDataSource
        implDirs.ObjDataModule.Source = newObjDataSource

        if implInput.ImplementAsNew then
            local newExternalSource = _getSourceAfterImplementAsNew(
                externalCategorySource, implInput.Name
            )
            parsedDataModel.ExternalCategoryListsModule
                .Source = newExternalSource
            
            externalCategoryLineNumber = _getNewlinesUpToPattern(
                newExternalSource, implInput.Name
            ) + 1
        end
    end)

    if not s_write then
        return Result.Err(e_write)
    end


    return Result.Ok{
        Directories = implDirs,
        ObjDataLineNumber = _getNewlinesUpToPattern(
            newObjDataSource, implInput.Name
        ) + 1,
        ShopDataLineNumber = _getNewlinesUpToPattern(
            newShopDataSource, implInput.Name
        ) + 1,
        ExternalCategoryLineNumber = externalCategoryLineNumber
    }
end


function _getNewlinesUpToPattern(str: string, pattern: string): number
    local i = string.find(str, pattern)
    if not i then return 0 end
    local substr = string.sub(str, 1, i)
    local _, c = string.gsub(substr, "\n", "\n")
    return c
end


function _getSourceAfterImplementAsNew(
    externalCategorySource: string, name: string
): string
    return string.gsub(
        externalCategorySource,
        "(m.New = )(%b{})",
        function(prefix, listSrc)
            return prefix .. _appendInListSrc(listSrc, `\n\t"{name}"\n`)
        end
    )
end


function _getSourceAfterAddOcPartToShopModule(
    shopDataSource: string,
    name: string,
    cost: number,
    categories: {T.EShopCategories}
): string
    local categoryContent = {}
    for _, category in pairs(categories) do
        table.insert(categoryContent, `"{category}"`)
    end

    local str = `module["{name}"] = \{{"\n"
        }\t__shopData = true,{"\n"
        }\tCost = {cost},{"\n"
        }\tCategories = \{ {table.concat(categoryContent, ", ")} \}{"\n"
        }\}`
    
    local newSource = string.gsub(
        shopDataSource, "(})(%s-)(return module)", function(before, _, after)
            return `{before}\n\n{str}\n\n{after}`, 1
        end
    )
    return newSource
end


--[[
    ListSrc is a balanced string beginning with '{' and ending with '}'
]]
function _appendInListSrc(listSrc: string, str: string): string
    local lastNonWhitespaceBeforeEnd = string.match(listSrc, "([^%s])%s-}$")
    local hasComma, hasContent =
        lastNonWhitespaceBeforeEnd == ",",
        lastNonWhitespaceBeforeEnd ~= "{"

    if hasContent then
        return string.gsub(
            listSrc,
            "([^%s])(%s-)(})$",
            function(before, _, after)
                return `{before}{hasComma and "" or ","} {str}{after}`
            end,
            1
        )
    else
        return `\{{str}\}`
    end
end

function _getSourceAfterAddOcPartToObjData(
    objDataSource: string, name: string, presetName: string?
): string
    local str = if presetName
        then `_new({string.format("%-50s, %s", `"name"`, `"presetName"`)})`
        else `_new("{name}")`
    
    return string.gsub(objDataSource, "(%b{})", function(listSrc: string)
        return _appendInListSrc(listSrc, `\n\t{str}\n`)
    end, 1)
end


return m