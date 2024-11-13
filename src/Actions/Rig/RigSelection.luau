local Selection = game:GetService("Selection")
local Result = require(script.Parent.Parent.Parent.Result)


export type RigSelection = {
	_t: "StaticRig",
    Rig: Model,
    Joints: Instance?
} | {
	_t: "AnimatedRig",
	AnimatedRig: Model
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
        return Result.Err("The selected object is not a rig. Rigs must be models.")
    end

	if not modelList.Parent then
		return Result.Err("No parent")
	end

	if modelList.Parent.ClassName == "Model" then
		return Result.Err("A rig root must not be a child of another model.")
	end

	local humanoid = modelList:FindFirstChildWhichIsA("Humanoid")
	if humanoid and humanoid:FindFirstChildWhichIsA("Animator") then
		return Result.Ok({
			_t = "AnimatedRig",
			AnimatedRig = modelList
		} :: RigSelection)
	end

	local rigRootModel = modelList:FindFirstChild("HumanoidRootPart")
	if not (rigRootModel and rigRootModel:IsA("Model") and rigRootModel.PrimaryPart) then
		return Result.Err("Rigs must have a child named HumanoidRootPart which is a Model.")
	end

    return Result.Ok({
		_t = "StaticRig",
        Rig = modelList,
        Joints = jointList
    } :: RigSelection)
end

return m