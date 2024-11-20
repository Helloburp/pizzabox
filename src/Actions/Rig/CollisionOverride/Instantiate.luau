local Parse = require(script.Parent.Parse)
local inst_root = script.Parent.Parent.Parent.Parent
local Result = require(inst_root.Result)
type Result<T,E> = Result.Result<T,E>

local inst_assets = inst_root.Assets
local COLLISION_FIX_SCRIPT = inst_assets.COLLISION_FIX_ASSETS
    :FindFirstChildWhichIsA("LocalScript")
    or error("Failed to find COLLISION_FIX script in plugin assets!")


local m = {}


function m.Clear(lowerTorsoModel: Model)
    local existingScripts = Parse.GetExistingScripts(lowerTorsoModel)
    for _, v in pairs(existingScripts) do
        v:Destroy()
    end
end


function m.New(lowerTorsoModel: Model): LocalScript
    local newScript = COLLISION_FIX_SCRIPT:Clone()
    newScript.Parent = lowerTorsoModel
    return newScript
end


return m