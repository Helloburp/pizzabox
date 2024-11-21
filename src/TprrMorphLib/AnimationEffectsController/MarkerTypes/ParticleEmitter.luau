local module = {}

function module:Emit(char: Model, id: string)
	for _, v in pairs(char:GetDescendants()) do
		if v:IsA("ParticleEmitter") and v.Name == id then
			v:Emit(v:GetAttribute("EMIT_AMOUNT") or v.Rate)
		end
	end
end

return module
