assert(plugin, "Script must run as a plugin.")

local Iris = require(script.Parent.Packages.Iris)

local MAIN_BUTTON_ID = "PIZZABOX"
local VERSION = "0.1.0"
local ICONS = {
    Opened = "rbxassetid://119063127894512",
    Closed = "rbxassetid://74405582882876"
}

local screenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.fromScale(0.5,0.5)

local toolbar = plugin:CreateToolbar(`PizzaBox v{VERSION}`)


local button = toolbar:CreateButton(
    MAIN_BUTTON_ID, "Toggles the PizzaBox menu.",
    ICONS.Closed, "PizzaBox"
)


function _setActive(state: boolean)
    button:SetActive(state)
    button.Icon = if state
        then ICONS.Opened
        else ICONS.Closed
    screenGui.Parent = if state
        then game:GetService("CoreGui")
        else script
end


local buttonState = Iris.State(false)
button.Click:Connect(function()
    buttonState:set(not buttonState:get())
    _setActive(buttonState:get())
end)


plugin.Unloading:Connect(function()
    buttonState:set(false)
    _setActive(false)
end)

Iris.Init(screenGui)

Iris:Connect(function()
    if not buttonState:get() then return end
    if Iris.Window(
        "PizzaBox", {isOpened = buttonState}
    ).closed() then
        _setActive(false)
    end
    Iris.End()
end)