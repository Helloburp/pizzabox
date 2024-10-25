
export type Result<T,E> = {
    Value: {_t: true, v: T} | {_t: false, v: E},
    Unwrap: (Result<T,E>) -> (T?, E?),
    UnwrapOr: (Result<T,E>, _f: (E) -> ()) -> (T?),
    UnwrapOrDefault: (Result<T,E>, _f: (E) -> (T)) -> (T),
    Expect: (Result<T,E>, err: string?) -> (T)
}

local m = {}

function m.Unwrap<T,E>(self: Result<T,E>): (T?, E?)
    return
        (if self.Value._t then self.Value.v else nil),
        (if not self.Value._t then self.Value.v else nil)
end

function m.UnwrapOr<T,E>(self: Result<T,E>, _f: (E) -> ()): (T?)
    if self.Value._t then return self.Value.v end
    _f(self.Value.v)
    return nil
end

function m.UnwrapOrDefault<T,E>(self: Result<T,E>, _f: (E) -> (T)):  T
    return if self.Value._t then self.Value.v else _f(self.Value.v)
end

function m.Expect<T,E>(self: Result<T,E>, err: string?)
    return self:UnwrapOr(function()
        error(err or "Exception occured!")
    end)
end

function m.Ok<T,E>(v: T): Result<T,E> return _new(true, v) end
function m.Err<T,E>(v: E): Result<T,E> return _new(false, v) end

--[[
    Performs a Pcall as a Result.

    T: If the function returns nil, it is set to 'true'.
        If the function does not return nil,
            it is the returned value.
]]
function m.Pcall<T>(...): Result<T,string>
    local s, e = pcall(...)
    return _new(s, s and (if e ~= nil then e else true) or e)
end


function _new<T,E>(state: boolean, v: T | E)
    local r = setmetatable(
        {Value = {_t = state, v = v} },
        {__index = m}
    )
    return r
end

return m