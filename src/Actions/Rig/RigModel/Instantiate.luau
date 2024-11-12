
local T = require(script.Parent.types)
type Rig = T.Rig
type RigModel = T.RigModel
type SkeletonVisualization = T.SkeletonVisualization


local m = {}

function m.Joint(name: string, cf: CFrame, size: number): BasePart
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.BrickColor = BrickColor.new("Medium stone grey")
    p.Material = Enum.Material.Neon
    p.CFrame = cf
    p.Size = Vector3.new(size, size, size)
    p.Transparency = 0.5

    return p
end

function m.AddJointToModel(model: Model, joint: BasePart)
    joint.Parent = model
    model.PrimaryPart = joint
end

function m.NewRigModel(name: string, jointName: string, jointSize: number, cf: CFrame): RigModel
    local model = Instance.new("Model")
    model.Name = name
    local joint = m.Joint(jointName, cf, jointSize)
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

    local function _recurse(parent: RigModel)
        for _, child in pairs(parent.Children) do
            local p = _generateSkeletonPiece(parent.Joint, child.Joint, crossSectionSize)
            p.Locked = true
            p.Parent = model

            table.insert(parts, p)
            _recurse(child)
        end
    end

    _recurse(ancestor)


    return {
        Parts = parts,
        Model = model,
        Highlight = highlight
    }
end


return m