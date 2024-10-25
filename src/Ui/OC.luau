local Iris = require(script.Parent.Parent.Parent.Packages.Iris)
local T = require(script.Parent.Parent["Ui.types"])
local m = {}

local ActionHandling = require(script.Parent.ActionHandling)

local inst_oc_actions = script.Parent.Parent.Actions.OC
local Parse = require(inst_oc_actions.Parse)
local OCActions = require(inst_oc_actions)
local T_OC = require(script.Parent.Parent.Actions["OC.types"])
local C_OC = require(script.Parent.Parent.Actions["OC.constants"])

local Selection = game:GetService("Selection")


function _implementOcPart(
    state: T.State,
    parsedDataModel: T_OC.ParsedDataModel,
    part: T_OC.ParsedOCPart,
    categories: {T_OC.EShopCategories}
)
    local function _f()
        local result = OCActions.ImplementOcPart(
            parsedDataModel,
            {
                Name = part.RootModel.Name,
                Model = part.RootModel,
                FazCoinCost = state.OcState.FazCoinCost:get(),
                ImplementAsNew = state.OcState.ImplementAsNew:get(),
                ObjectDataModuleName = state.OcState.ObjDataModuleName:get(),
                ShopDataModuleName = state.OcState.ShopDataModuleName:get(),
                Categories = categories
            }
        )

        local details, _ = result:Unwrap()
        if details then
            state.Plugin:OpenScript(
                details.Directories.ObjDataModule,
                details.ObjDataLineNumber
            )
            state.Plugin:OpenScript(
                details.Directories.ShopDataModule,
                details.ShopDataLineNumber
            )

            if details.ExternalCategoryLineNumber then
                state.Plugin:OpenScript(
                    parsedDataModel.ExternalCategoryListsModule,
                    details.ExternalCategoryLineNumber
                )
            end

        end

        return result
    end

    return ActionHandling.DoRecordedActionResult("Implement OC Part", _f)
end


function _modelSelectedActions(model: Model)
    if Iris.Button("Convert Into OC Part").clicked() then
        ActionHandling.DoRecordedAction("Convert Model to OC Part", function()
            local newPart = OCActions.NewOcPartFromModel(model)
            Selection:Set({newPart.RootModel})
        end)
    end
end


function _supplementalCategoryBoxes(): {T_OC.EShopCategories}
    local items = {}
    Iris.Table(3)
    for _, category in pairs(C_OC.ALL_CATEGORIES) do
        if Iris.Checkbox(category).isChecked.value then
            table.insert(items, category)
        end
        Iris.NextColumn()
    end
    Iris.End()

    return items
end


function _comboFromList(
    name: string,
    options: {},
    indexState
)
    Iris.Combo({name}, {index = indexState})
    for _, val in pairs(options) do
        Iris.Selectable({val, val}, {index = indexState})
    end
    Iris.End()
end

function _implementationMenu(
    state: T.State,
    parsedDataModel: T_OC.ParsedDataModel,
    part: T_OC.ParsedOCPart
)
    Iris.InputNum({"Cost"}, {number = state.OcState.FazCoinCost})
    _comboFromList(
        "ObjectData Domain",
        C_OC.ALL_MODEL_TYPES,
        state.OcState.ObjDataModuleName
    )
    _comboFromList(
        "ShopData Domain",
        C_OC.ALL_SHOP_TYPES,
        state.OcState.ShopDataModuleName
    )
    Iris.Checkbox({"Tag as New"}, {isChecked = state.OcState.ImplementAsNew})

    Iris.Tree("Extra Categories")
    local categories = _supplementalCategoryBoxes()
    Iris.End()

    if Iris.Button("Implement").clicked() then
        state.OcState.LastImplementationError = ""
        local r = _implementOcPart(
            state, parsedDataModel, part, categories
        )
        r:UnwrapOr(function(e)
            state.OcState.LastImplementationError = e
        end)
    end
    if state.OcState.LastImplementationError ~= "" then
        Iris.Text{
            state.OcState.LastImplementationError,
            [Iris.Args.Text.Color] = Color3.new(1,0.5,0.5)
        }
    end
end


function _partSelectedActions(state: T.State, part: T_OC.ParsedOCPart)
    local parsedDataModel, err = Parse.ParseDataModel():Unwrap()
    if parsedDataModel then
        Iris.Tree("Implementation", {isUncollapsed = true})
        _implementationMenu(state, parsedDataModel, part)
        Iris.End()
    else
        Iris.Text(`Implementation is not available.\n({err})`)
    end

    Iris.Separator()
    Iris.SameLine()
    if Iris.Button("Apply Automatic Attributes").clicked() then
        ActionHandling.DoRecordedAction(
            "Apply Automatic Attributes",
            function()
                OCActions.ApplyAttributesFromModel(
                    part.RootModel, part.VisualModel
                )
            end
        )
    end
    Iris.End()
    
end

function _selectionActions(state: T.State)
    local selectedModel = Selection:Get()[1]
    local isModelSelected = selectedModel and selectedModel:IsA("Model")
    local parsedOCPart, parseError

    if isModelSelected then
        parsedOCPart, parseError = Parse.ParseOCPart(selectedModel):Unwrap()
    else
        parsedOCPart, parseError = nil, nil
    end

    local stateText = if not isModelSelected
        then "No model selected."
        elseif parsedOCPart then "OC part selected."
        else `Non-OC-Part Model selected.\n({parseError})`
    
    Iris.Text(stateText)
    
    Iris.Separator()
    if not isModelSelected then return end


    if parsedOCPart then
        _partSelectedActions(state, parsedOCPart)
    else
        _modelSelectedActions(selectedModel)
    end
end

function m.Cycle(state: T.State)
    Iris.Window("OC Tools", {isOpened = state.WindowStates.OC})
    _selectionActions(state)
    Iris.End()
end

function m.State(): T.OcState
    return {
        ObjDataModuleName = Iris.State(C_OC.ALL_MODEL_TYPES[1]),
        FazCoinCost = Iris.State(0),
        ShopDataModuleName = Iris.State(C_OC.ALL_MODEL_TYPES[1]),
        ImplementAsNew = Iris.State(true),
        LastImplementationError = ""
    }
end


return m