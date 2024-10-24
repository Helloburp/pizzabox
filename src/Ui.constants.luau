local IrisTemplateConfig = 
    require(script.Parent.Parent.Packages.Iris).TemplateConfig

local RED_CONFIG = (function()
    local myConfig = table.clone(IrisTemplateConfig.colorDark)
    for k, v in pairs(myConfig) do
        if typeof(v) ~= "Color3" then continue end
        myConfig[k] = Color3.new(v.B, v.G, v.R)
    end
    return myConfig
end)()

return {
    MAIN_BUTTON_ID = "PIZZABOX",
    VERSION = require(script.Parent.VERSION),
    IRIS_CONFIGS = {
        RED_CONFIG = RED_CONFIG
    },
    ICONS = {
        Opened = "rbxassetid://119063127894512",
        Closed = "rbxassetid://74405582882876"
    },
}