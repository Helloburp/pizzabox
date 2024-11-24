local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>


export type RigSelection = {
	_t: "StaticRig",
    Rig: Model,
} | {
	_t: "AnimatedRig",
	AnimatedRig: Model
} | {
	_t: "MultiSelect",
	AnimatedRigs: {Model},
	StaticRigs: {Model}
}

local m = {}


function m.ParseAll(selections: {Instance}): Result<RigSelection,string>
	if #selections == 0 then
		return Result.Err("Not enough selections.")
	end

	if #selections == 1 then
		return m.Parse(selections[1])
	end

	local animatedRigs, staticRigs = {}, {}
	for _, selection in selections do
		local result = m.Parse(selection):Ok()
		if not result then continue end
		if result._t == "AnimatedRig" then
			table.insert(animatedRigs, result.AnimatedRig)
		elseif result._t == "StaticRig" then
			table.insert(staticRigs, result.Rig)
		end
	end

	if #animatedRigs + #staticRigs == 0 then return Result.Err("Invalid Multi-Select.") end

	return Result.Ok({
		_t = "MultiSelect",
		AnimatedRigs = animatedRigs,
		StaticRigs = staticRigs
	} :: RigSelection)
end

function m.Parse(inst: Instance): Result<RigSelection,string>

    if not (inst and inst:IsA("Model")) then
        return Result.Err("The selected object is not a rig. Rigs must be models.")
    end

	if not inst.Parent then
		return Result.Err("No parent")
	end

	if inst.Parent.ClassName == "Model" then
		return Result.Err("A rig root must not be a child of another model.")
	end

	local humanoid = inst:FindFirstChildWhichIsA("Humanoid")
	if humanoid and humanoid:FindFirstChildWhichIsA("Animator") then
		return Result.Ok({
			_t = "AnimatedRig",
			AnimatedRig = inst
		} :: RigSelection)
	end

	local rigRootModel = inst:FindFirstChild("HumanoidRootPart")
	if not (rigRootModel and rigRootModel:IsA("Model") and rigRootModel.PrimaryPart) then
		return Result.Err("Rigs must have a child named HumanoidRootPart which is a Model.")
	end

    return Result.Ok({
		_t = "StaticRig",
        Rig = inst,
    } :: RigSelection)
end

return m