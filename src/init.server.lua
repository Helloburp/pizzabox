assert(plugin, "Script must run as a plugin.")

local Iris = require(script.Parent.Packages.Iris)
local Ui = require(script.Ui)

local C = require(script["Ui.constants"])
local T = require(script["Ui.types"])

local state: T.State = {
    PluginOpenState = Iris.State(false),
    SubMenuStates = {
        Rig = Iris.State(false)
    },
    LastRigActionError = ""
}

local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local toolbar = plugin:CreateToolbar(`PizzaBox v{C.VERSION}`)
local button = toolbar:CreateButton(
    C.MAIN_BUTTON_ID, "Toggles the PizzaBox menu.",
    C.ICONS.Closed, "PizzaBox"
)


function _setActive(state: boolean)
    button:SetActive(state)
    button.Icon = if state
        then C.ICONS.Opened
        else C.ICONS.Closed
    screenGui.Parent = if state
        then game:GetService("CoreGui")
        else script
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
Iris.UpdateGlobalConfig(C.IRIS_CONFIGS.RED_CONFIG)

Iris:Connect(Ui.FromState(state, function() _setActive(false) end))