local IrisTemplateConfig = 
    require(script.Parent.Parent.Packages.Iris).TemplateConfig


function _newConfig(_modulate: (Color3) -> Color3)
    local myConfig = table.clone(IrisTemplateConfig.colorDark)
    for k, v in pairs(myConfig) do
        if typeof(v) ~= "Color3" then continue end
        myConfig[k] = _modulate(v)
    end
    return myConfig
end

function _newSetHue(targetColor: Color3): (Color3) -> (Color3)
    local targetHue = targetColor:ToHSV()
    return function(c: Color3)
        local _, s, v = c:ToHSV()
        return Color3.fromHSV(targetHue, s, v)
    end
end


function _getPlugin(): Plugin
    error("Must be implemented by the Server Script!")
end

return {
    GET_PLUGIN = _getPlugin,
    MAIN_BUTTON_ID = "PIZZABOX",
    VERSION = require(script.Parent.VERSION),
    IRIS_CONFIGS = {
        DEFAULT = _newConfig(function(v)
            return Color3.new(v.B, v.G, v.R)
        end),
        PURPLE = _newConfig(
            _newSetHue(BrickColor.new("Alder").Color)
        ),
        RED = _newConfig(
            _newSetHue(BrickColor.new("Really red").Color)
        ),
        GOLD = _newConfig(
            _newSetHue(BrickColor.new("Gold").Color)
        ),
        BLUE = _newConfig(
            _newSetHue(BrickColor.new("Electric blue").Color)
        ),
    },
    ICONS = {
        Opened = "rbxassetid://119063127894512",
        Closed = "rbxassetid://74405582882876"
    },
    SETTING_KEYS = {
        THEME = "PIZZABOX_THEME"
    },
    COLORS = {
        ERROR = Color3.new(1, 0.5, 0.5),
        WARNING = Color3.new(1, 0.8, 0.5),
        NOTICE = Color3.new(0.7, 0.7, 1)
    }
}