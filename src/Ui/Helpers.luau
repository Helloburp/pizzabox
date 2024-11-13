local T = require(script.Parent.Parent["Ui.types"])
type TaggedText = T.TaggedText

local ServerStorage = game:GetService("ServerStorage")
local inst_assets = script.Parent.Parent.Assets


local ActionHandling = require(script.Parent.ActionHandling)
local Output = require(script.Parent.Output)
local Result = require(script.Parent.Parent.Result)
type Result<T,E> = Result.Result<T,E>


local m = {}


function m.RecordActionToOutputPcall<T>(
    list: {TaggedText},
    id: string,
    _f: () -> ()
)
    Output.Set(list, id, ActionHandling.DoRecordedAction(id, _f):Err())
end

function m.RecordActionToOutputResult<T>(
    list: {TaggedText},
    id: string,
    _f: () -> Result<T,string>
)
    Output.Set(list, id, ActionHandling.DoRecordedActionResult(id, _f):Err())
end


function m.TestAnims(): {KeyframeSequence | Animation}?
    local root = ServerStorage:FindFirstChild("PIZZABOX_TESTANIMS")
    if not (root) then return nil end

    local tab = {}
    for _, v in pairs(root:GetDescendants()) do
        if not (v:IsA("KeyframeSequence") or v:IsA("Animation")) then continue end
        table.insert(tab, v)
    end
    return tab
end

function m.NewTestAnims()
    inst_assets.PIZZABOX_TESTANIMS:Clone().Parent = ServerStorage
end


return m