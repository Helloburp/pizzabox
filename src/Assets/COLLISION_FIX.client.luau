local char = game.Players.LocalPlayer.Character

while game:GetService("RunService").Heartbeat:Wait() do
	for _, v in pairs(char:GetChildren()) do
		if not v:IsA("BasePart") then continue end
		if not script:GetAttribute(v.Name) then continue end

		v.CanCollide = false
	end
end