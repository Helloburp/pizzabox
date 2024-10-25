local Result = require(script.Parent.Parent.Parent.Result)
local m = {}


local utilities = require(script.Parent.MorphUtils)

function m.MakeRig(modelParent, jointParent): Result.Result<any, string>
	local success, err = false, ""
	
	success, err = utilities:TestModelListIntegrity(modelParent)
	success, err = utilities:TestPartListIntegrity(jointParent)
	
	if not success then
		return Result.FromE(err)
	end
	
	local modelIndex = {}
	
	for jointName, partName in pairs(utilities.JointPartIndex) do
		local curModel = modelParent:FindFirstChild(partName)
		
		if not curModel then
			curModel = Instance.new("Model", modelParent)
			curModel.Name = partName
		end
		
		local curJoint = jointParent:FindFirstChild(jointName)
		
		modelIndex[partName] = curModel
		curJoint.Parent = modelIndex[partName]
		modelIndex[partName].PrimaryPart = curJoint
	end
	
	local function Recurse(level, parent)
		for partName, children in pairs(level) do
			local curPart = modelIndex[partName]
			modelIndex[partName].Parent = parent or modelParent
			Recurse(children, curPart)
		end
	end
	
	Recurse(utilities.RigTree)
	
	jointParent.Parent = nil
	
	return Result.FromT(true)
end


return m
