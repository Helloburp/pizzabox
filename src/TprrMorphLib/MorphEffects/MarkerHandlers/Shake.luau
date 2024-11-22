local Workspace = game:GetService("Workspace")
local m = {}

export type DoShake = (
    magnitude: number,
    roughness: number,
    fadeInTime: number,
    fadeOutTime: number,
    posInfluence: Vector3,
    rotInfluence: Vector3
) -> ()


function m.CameraShake(intensity: number, origin: Vector3, _shake: DoShake)
	local dist = (Workspace.CurrentCamera.CFrame.Position - origin).Magnitude
	local max = tonumber(intensity)
    if dist <= max then return end
    if game.Workspace.Camera.CameraType ~= Enum.CameraType.Custom then return end

    local magnitude = (max - dist) * intensity/6
    _shake(
        magnitude,
        magnitude,
        0.1,
        0.1,
        Vector3.new(0.05, 0.05, 0.05),
        Vector3.new(0.1, 0.1, 0.1)
    )
end


return m