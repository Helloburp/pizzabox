local Selection = game:GetService("Selection")
local Result = require(script.Parent.Parent.Parent.Result)


export type RigSelection = {
    Rig: Model,
    Joints: Instance?
}

local m = {}

function m.Parse(): Result.Result<RigSelection, string>
	local selections = Selection:Get()
	
	if #selections < 1 then
		return Result.Err("Not enough selections.")
	end
	
	local selA = selections[1]
	local selB = selections[2]
	
	local modelList = nil
	local jointList = nil
	
	if selA:FindFirstChildOfClass("Model") then
		modelList, jointList = selA, selB
	else
		modelList, jointList = selB, selA
	end

    if not (modelList and modelList:IsA("Model")) then
        return Result.Err("The selected object is not a rig.")
    end

    return Result.Ok{
        Rig = modelList,
        Joints = jointList
    }
end

return m