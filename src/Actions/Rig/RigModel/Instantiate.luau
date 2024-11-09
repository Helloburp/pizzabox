
local T = require(script.Parent.types)
type Rig = T.Rig
type RigModel = T.RigModel
type SkeletonVisualization = T.SkeletonVisualization


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

function _generateSkeletonPiece(parentPrimary: BasePart, childPrimary: BasePart, crossSectionSize: Vector2)
    local diff = (parentPrimary.Position - childPrimary.Position)
    local midpoint = parentPrimary.Position - diff/2
    
    local p = Instance.new("Part")
    p.Size = Vector3.new(
        crossSectionSize.X,
        crossSectionSize.Y,
        diff.Magnitude
    )
    p.CFrame = CFrame.new(midpoint, childPrimary.Position)
    p.Anchored = true
    
    return p
end


function m.NewSkeletonVisualization(
    ancestor: RigModel,
    crossSectionSize: Vector2
): SkeletonVisualization

    local model = Instance.new("Model")
    model.Archivable = false

    local highlight = Instance.new("Highlight", model)
    local parts = {}

    for _, child in pairs(ancestor.Children) do
        local p = _generateSkeletonPiece(ancestor.Joint, child.Joint, crossSectionSize)
        p.Parent = model

        table.insert(parts, p)
        m.NewSkeletonVisualization(child, crossSectionSize)
    end

    return {
        Parts = parts,
        Model = model,
        Highlight = highlight
    }
end


return m