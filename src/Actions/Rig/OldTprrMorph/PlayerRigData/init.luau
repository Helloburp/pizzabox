local module = {}

function module:GetOffsetFromRoot(partName)
	local rootCf = script.Dummy.HumanoidRootPart.CFrame
	local otherCf = script.Dummy:FindFirstChild(partName).CFrame
	return rootCf:ToObjectSpace(otherCf) -- Difference from root to other
end

return module
