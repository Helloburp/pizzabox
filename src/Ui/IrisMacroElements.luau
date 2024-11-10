local inst_packages = script.Parent.Parent.Parent.Packages
local Iris = require(inst_packages.Iris)

local m = {}


function m.WrappedRichText(...)
    Iris.PushConfig({RichText = true, TextWrapped = true})
    Iris.Text(...)
    Iris.PopConfig()
end


return m