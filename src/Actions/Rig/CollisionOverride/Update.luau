local m = {}

function m.UpdateSettings(existingScript: LocalScript, newSettings: {[Enum.BodyPartR15]: boolean})
    for _, enumItem: Enum.BodyPartR15 in pairs(Enum.BodyPartR15:GetEnumItems()) do
        existingScript:SetAttribute(enumItem.Name, newSettings[enumItem] or nil)
    end
end

return m