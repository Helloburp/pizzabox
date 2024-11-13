local Result = require(script.Parent.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>

local T = require(script.types)
type MorphedRig = T.MorphedRig

local LinkedComponent = require(script.Parent.LinkedComponent)
local MakeAnimatableRig = require(script.Parent.MakeAnimatableRig)
local Parse = require(script.Parse)

local m = {}


function m.NewAnimationRig(rig: Model): Result<MorphedRig,string>
    local result = MakeAnimatableRig.MakeRig(rig)
    local model = result:Ok()
    if model then
        model:PivotTo(rig:GetPivot())
        model.Parent = rig.Parent
    end

    local morphedRig = Parse.ParseMorphedRig(model)
        :Expect("Failed to parse default animatable rig.")
    
    return Result.Ok(morphedRig)
end


function m.AnimateExistingRig(rig: Model, animatedRig: Model)
    local oldParent = rig.Parent
    animatedRig:PivotTo(rig:GetPivot())
    rig.Parent = game:GetService("ServerStorage")
    animatedRig.Parent = oldParent
end


function m.StopAnimatingExistingRig(rig: Model, animatedRig: Model)
    local oldParent = animatedRig.Parent
    animatedRig.Parent = game:GetService("ServerStorage")
    rig.Parent = oldParent
end


function m.StepAnimation(morphedRig: MorphedRig, deltaTime: number)
    morphedRig.Animator:StepAnimations(deltaTime)
    LinkedComponent.UpdateRigAttachments(morphedRig.Rig.Root.Model)
end


function m.StopAnimations(morphedRig: MorphedRig)
    for _, animation in pairs(morphedRig.Animator:GetPlayingAnimationTracks()) do
        animation:Stop()
    end
end


function m.LoadId(
    morphedRig: MorphedRig,
    id: string
): AnimationTrack
    local animation = Instance.new("Animation")
    animation.AnimationId = id

    local track = morphedRig.Animator:LoadAnimation(animation)
    animation:Destroy()

    return track
end


return m