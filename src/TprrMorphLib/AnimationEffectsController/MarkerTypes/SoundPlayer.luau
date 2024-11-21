local module = {}

function module:New(soundLibrary)
	local o = {}
	
	function o:PlaySound(soundName, parent, properties)
		local sound = nil
		for _, v in pairs(soundLibrary:GetDescendants()) do
			if v:IsA("Sound") and v.Name == soundName then
				sound = v
			end
		end
		
		if sound then
			local clone = sound:Clone()
			clone.Parent = parent
			clone:SetAttribute("__AnimSound", true)
			
			if typeof(properties) == "table" then
				for i, v in pairs(properties) do
					clone[i] = v
				end
			end
			
			coroutine.resume(coroutine.create(function()
				if not clone.IsLoaded then
					clone.Loaded:Wait()
				end
				
				clone.Ended:Connect(function()
					clone:Destroy()
				end)
				
				clone:Play()
				
				wait(clone.TimeLength)
				clone:Destroy()
				
			end))
		else
			warn("Attempting to play a sound that does not exist:", soundName)
		end
	end
	
	return o
end

return module
