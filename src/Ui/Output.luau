local T = require(script.Parent.Parent["Ui.types"])
local C = require(script.Parent.Parent["Ui.constants"])
type ActionOutput = T.ActionOutput
type TaggedText = T.TaggedText



local m = {}


function m.New(): ActionOutput
    return { Errors = {}, Warnings = {}, Notices = {} }
end


function m.Set(list: {TaggedText}, id: string, text: string?)
    local i = nil
    for _i, v in ipairs(list) do
        if v.Id ~= id then continue end
        i = _i
        break
    end

    if i then
        if text then
            list[i].Text = text
        else
            table.remove(list, i)
        end
    elseif text then
        table.insert(list, {Id = id, Text = text})
    end
end


function m.Format(self: ActionOutput): string
    local lines = {}
    for _, taggedText in pairs(self.Errors) do
        table.insert(lines, `<font color="#{C.COLORS.ERROR:ToHex()}">🛑 {taggedText.Text}</font>`)
    end
    for _, taggedText in pairs(self.Warnings) do
        table.insert(lines, `<font color="#{C.COLORS.WARNING:ToHex()}">⚠️ {taggedText.Text}</font>`)
    end
    for _, taggedText in pairs(self.Notices) do
        table.insert(lines, `<font color="#{C.COLORS.NOTICE:ToHex()}">ℹ️️ {taggedText.Text}</font>`)
    end

    return table.concat(lines, "\n")
end



return m