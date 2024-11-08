local inst_attachments = script.Parent.Attachments
local T_LINKED = require(inst_attachments["Parse.types"])
type ActiveRiggedModel = T_LINKED.ActiveRiggedModel

local ParseLinked = require(inst_attachments.Parse)

local T = require(script.Parent["RigComponents.types"])
type RigModel = T.RigModel


local m = {}

function m.Joint(name: string, cf: CFrame): BasePart
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.BrickColor = BrickColor.new("Medium stone grey")
    p.CFrame = cf

    return p
end

function m.AddJointToModel(model: Model, joint: BasePart)
    joint.Parent = model
    model.PrimaryPart = joint
end

function m.NewRigModel(name: string, jointName: string, cf: CFrame): RigModel
    local model = Instance.new("Model")
    model.Name = name
    local joint = m.Joint(jointName, cf)
    m.AddJointToModel(model, joint)

    return {
        Model = model,
        Joint = joint,
        Children = {}
    }
end


function m.ActiveRiggedModelFromRigModel(self: RigModel): ActiveRiggedModel
    return ParseLinked.ParseActiveRiggedModel(self.Model, self.Model)
end

return m