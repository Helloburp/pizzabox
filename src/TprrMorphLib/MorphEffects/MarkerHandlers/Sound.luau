
local Debris = game:GetService("Debris")

local m = {}

function m.PlayThenDestroyFromLibrary(
	soundName: string,
	soundLibrary: Instance,
	parent: Instance,
	timeout: number?
)
	local librarySound = m.FetchSound(soundName, soundLibrary)		

	if not librarySound then
		return
	end

	m.PlayThenDestroy(m.ApplyProperties(librarySound:Clone(), parent), timeout)
end


function m.FetchSound(soundName: string, libraryRoot: Instance): Sound?
	local sound = libraryRoot:FindFirstChild(soundName, true)
	if not (sound and sound:IsA("Sound")) then return nil end
	return sound
end


function m.ApplyProperties(sound: Sound, parent: Instance): Sound
	sound.Parent = parent
	sound:SetAttribute("__AnimSound", true)
	return sound
end


function m.PlayThenDestroy(sound: Sound, timeout: number?)
	Debris:AddItem(sound, timeout or 300)

	task.spawn(function()
		if not sound.IsLoaded then sound.Loaded:Wait() end
		sound:Play()
		sound.Ended:Wait()
		sound:Destroy()
	end)
end


return m
