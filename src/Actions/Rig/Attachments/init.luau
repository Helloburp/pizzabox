local Update = require(script.Update)
local Parse = require(script.Parse)

local m = {}

function m.UpdateRigAttachments(model: Model)
    local riggedModel = Parse.ParseActiveRiggedModel(model, model)
    Update.UpdateActiveRiggedModel(riggedModel)
end

return m