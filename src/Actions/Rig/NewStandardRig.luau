
local m = {}

local inst_assets = script.Parent.Parent.Parent.Assets

function m.New(cf: CFrame): Model
    local rig = inst_assets.StandardRig:Clone()
    rig.Parent = game.Workspace
    rig:PivotTo(cf)
    return rig
end

return m
