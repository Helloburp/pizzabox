local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Result = require(script.Parent.Parent.Result)

local m = {}


function m.DoRecordedActionResult<T,E>(
    name: string, _f: () -> (Result.Result<T,E>)
): Result.Result<T,E>
    local isRecording = ChangeHistoryService:TryBeginRecording(name)
    assert(
        isRecording,
        `PLUGIN ERROR: Attempted to start a recording before{" "
        }another one was finished.`
    )
    local s_r, r = pcall(_f)
    local s, e = nil, nil

    if s_r then
        s, e = r:Unwrap()
    end

    ChangeHistoryService:FinishRecording(
        isRecording,
        if s and s_r then Enum.FinishRecordingOperation.Commit
            else Enum.FinishRecordingOperation.Cancel
    )

    if not s then
        warn(`Plugin action '{name}' had an error during execution:\n{e}`)
    end

    return r
end


function m.DoRecordedAction<T>(name: string, _f: () -> ()): Result.Result<T, string>
    return m.DoRecordedActionResult(name, function()
        return Result.Pcall(_f)
    end)
end

return m