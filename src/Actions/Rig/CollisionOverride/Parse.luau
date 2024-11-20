
local inst_root = script.Parent.Parent.Parent.Parent
local Result = require(inst_root.Result)
type Result<T,E> = Result.Result<T,E>

local inst_assets = inst_root.Assets
local COLLISION_FIX_SCRIPT = inst_assets.COLLISION_FIX_ASSETS
    :FindFirstChildWhichIsA("LocalScript")
    or error("Failed to find COLLISION_FIX script in plugin assets!")


local m = {}


function m.GetExistingScripts(lowerTorsoModel: Model): {LocalScript}
    local tab = {}
    for _, child in pairs(lowerTorsoModel:GetChildren()) do
        if not child:IsA("LocalScript") then continue end
        if child.Name ~= COLLISION_FIX_SCRIPT.Name then continue end

        table.insert(tab, child)
    end

    return tab
end


function m.ParseValidScript(lowerTorsoModel: Model): Result<LocalScript, string>
    local existingScript = m.GetExistingScripts(lowerTorsoModel)[1]
    if not existingScript then
        return Result.Err(
            `Unable to find LocalScript named '{COLLISION_FIX_SCRIPT.Name}' \z
            in LowerTorsoModel`
        )
    end

    if existingScript.Source ~= COLLISION_FIX_SCRIPT.Source then
        return Result.Err(`Found a COLLISION_FIX script, but its code is outdated.`)
    end

    return Result.Ok(existingScript)
end

function m.GetSettings(existingScript: LocalScript): {[Enum.BodyPartR15]: boolean }
    local settings = {}
    for _, enumItem: EnumItem in pairs(Enum.BodyPartR15:GetEnumItems()) do
        settings[enumItem.Name] = existingScript:GetAttribute(enumItem.Name) ~= nil
    end
    return settings
end


return m