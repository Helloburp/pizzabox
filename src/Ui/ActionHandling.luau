local ChangeHistoryService = game:GetService("ChangeHistoryService")

local m = {}


function m.DoRecordedAction(name: string, _f: () -> ())
    local isRecording = ChangeHistoryService:TryBeginRecording(name)
    assert(
        isRecording,
        [[PLUGIN ERROR: Attempted to start a recording before \
            another one was finished.]]
    )
    local s, e = pcall(_f)
    ChangeHistoryService:FinishRecording(
        isRecording,
        if s then Enum.FinishRecordingOperation.Commit
            else Enum.FinishRecordingOperation.Cancel
    )

    if not s then
        warn(`Plugin action '{name}' had an error during execution:\n{e}`)
    end
end

return m