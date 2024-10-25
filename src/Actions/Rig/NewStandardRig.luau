
local m = {}

function m.New(cf: CFrame): Model
    local rig = script.Parent.StandardRig:Clone()
    rig.Parent = game.Workspace
    rig:PivotTo(cf)
    return rig
end

return m
