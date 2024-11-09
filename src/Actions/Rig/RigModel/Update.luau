-- Disappears in order of 1->3
local LOD_ATTR = "__LOD_ATTR_ORIG_TRANSPARENCY"
local JOINT_ATTR = "__JOINT_ATTR_ORIG_TRANSPARENCY"

local T = require(script.Parent.types)
type RigModel = T.RigModel


local m = {}


function m.DisableLevelOfDetailDemo(rootModel: Model)
    for _, part in pairs(rootModel:GetDescendants()) do
        if not part:IsA("BasePart") then continue end
        local orig = tonumber(part:GetAttribute(LOD_ATTR))
        part.Transparency = orig and orig or part.Transparency

        part:SetAttribute(LOD_ATTR, nil)
    end
end


function m.SetLevelOfDetailDemo(rootModel: Model, level: number)
    for _, part in pairs(rootModel:GetDescendants()) do
        if not part:IsA("BasePart") then continue end
        local myLevel = tonumber(string.match(part.Name, "^LOD(%d-)$"))
        if not myLevel then continue end
        if part:GetAttribute(LOD_ATTR) then continue end
        if myLevel > level then continue end

        part:SetAttribute(LOD_ATTR, part.Transparency)
        part.Transparency = 1
    end
end


function m.DisableJointTransparency(rootRigModel: RigModel)
    local function _recurse(rigModel: RigModel)
        local joint = rigModel.Joint
        local orig = tonumber(joint:GetAttribute(JOINT_ATTR))
        joint.Transparency = orig and orig or joint.Transparency

        joint:SetAttribute(JOINT_ATTR, nil)
        for _, child in pairs(rigModel.Children) do
            _recurse(child)
        end
    end

    _recurse(rootRigModel)
end


function m.MakeJointsInvisible(rootRigModel: RigModel)
    local function _recurse(rigModel: RigModel)
        local joint = rigModel.Joint
        if not joint:GetAttribute(JOINT_ATTR) then
            joint:SetAttribute(JOINT_ATTR, joint.Transparency)
            joint.Transparency = 1
        end

        for _, child in pairs(rigModel.Children) do
            _recurse(child)
        end
    end

    _recurse(rootRigModel)
end


return m