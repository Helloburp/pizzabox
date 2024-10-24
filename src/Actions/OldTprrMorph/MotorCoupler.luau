-- Currently unused


local module = {}

local plrRigData = require(script.Parent.PlayerRigData)
local morphHelper = require(script.Parent.MorphHelper)

function module:GetOffsetsForR15Motor(motor, rigOrigin)
	local p0, p1 = motor.Part0, motor.Part1
	local rigOffset0 = plrRigData:GetOffsetFromRoot(p0.Name)
	local rigOffset1 = plrRigData:GetOffsetFromRoot(p1.Name)

	--local rigRootPos = rigModels.HumanoidRootPart:FindFirstChildOfClass("Part").CFrame	-- Get the position of the rig
	local jointOffset = rigOrigin:ToObjectSpace(motor.Part0.CFrame)		-- Distance from rig root to motor

	local jointOffset0 = rigOffset0:ToObjectSpace(jointOffset)	-- Distance from p0 to motor
	local jointOffset1 = rigOffset1:ToObjectSpace(jointOffset)	-- Distance from p1 to motor
	
	return jointOffset0, jointOffset1
end

function module:GetOffsetsForCustomMotor(motor, parentOrigin)
	return motor.Part0.CFrame:inverse() * parentOrigin, CFrame.new()
end

return module
