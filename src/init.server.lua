assert(plugin, "Script must run as a plugin.")


local C = require(script["Ui.constants"])
local T = require(script["Ui.types"])

C.GET_PLUGIN = function()
    return plugin
end

local Iris = require(script.Parent.Packages.Iris)
local Ui = require(script.Ui)

function _getThemeId(): string
    local retrieved = plugin:GetSetting(C.SETTING_KEYS.THEME)
    if retrieved and C.IRIS_CONFIGS[retrieved] then
        return retrieved
    else
        return "DEFAULT"
    end
end

function _setThemeId(str: string)
    plugin:SetSetting(C.SETTING_KEYS.THEME, str)
end


local state: T.State = {
    Plugin = plugin,
    PluginOpenState = Iris.State(false),
    WindowStates = {
        Rig = Iris.State(false),
        OC = Iris.State(false)
    },
    Settings = {
        Theme = Iris.State(_getThemeId())
    },

    OcState = require(script.Ui.OC).State(),
    RigState = require(script.Ui.Rig).State()
}

local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local toolbar = plugin:CreateToolbar(`PizzaBox {C.VERSION}`)
local button = toolbar:CreateButton(
    C.MAIN_BUTTON_ID, "Toggles the PizzaBox menu.",
    C.ICONS.Closed, "PizzaBox"
)


function _setActive(isActive: boolean)
    button:SetActive(isActive)
    button.Icon = if isActive
        then C.ICONS.Opened
        else C.ICONS.Closed
    screenGui.Parent = if isActive
        then game:GetService("CoreGui")
        else script

    if not isActive then
        Ui.Cleanup(state)
    end
end


function _updateTheme()
    _setThemeId(state.Settings.Theme:get())
    Iris.UpdateGlobalConfig(C.IRIS_CONFIGS[state.Settings.Theme:get()])
end


button.Click:Connect(function()
    state.PluginOpenState:set(not state.PluginOpenState:get())
    _setActive(state.PluginOpenState:get())
end)


plugin.Unloading:Connect(function()
    state.PluginOpenState:set(false)
    _setActive(false)
    Iris.Shutdown()
end)

Iris.Init(screenGui)
_updateTheme()

state.Settings.Theme:onChange(_updateTheme)

Iris:Connect(Ui.FromState(state, function() _setActive(false) end))