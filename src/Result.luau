
export type Result<T,E> = {
    Value: {_t: true, v: T} | {_t: false, v: E},

    Unwrap: (Result<T,E>) -> (T?, E?),
    UnwrapOr: (Result<T,E>, _f: (E) -> ()) -> (T?),
    UnwrapOrDefault: (Result<T,E>, _f: (E) -> (T)) -> (T),

    OrElse: <R>(Result<T,E>, _f: (E) -> (R)) -> (T?, R?),
    AndThen: <R>(Result<T,E>, _f: (T) -> (R)) -> (R?, E?),

    Expect: (Result<T,E>, err: string?) -> (T),

    Ok: (Result<T,E>) -> T?,
    Err: (Result<T,E>) -> E?,
}

local m = {}

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


local Result = {}

function Result.Unwrap<T,E>(self: Result<T,E>): (T?, E?)
    return
        (if self.Value._t then self.Value.v else nil),
        (if not self.Value._t then self.Value.v else nil)
end

function Result.UnwrapOr<T,E>(self: Result<T,E>, _f: (E) -> ()): (T?)
    if self.Value._t then return self.Value.v end
    _f(self.Value.v)
    return nil
end

function Result.UnwrapOrDefault<T,E>(self: Result<T,E>, _f: (E) -> (T)):  T
    return if self.Value._t then self.Value.v else _f(self.Value.v)
end

function Result.Expect<T,E>(self: Result<T,E>, err: string?)
    return self:UnwrapOr(function()
        error(err or "Exception occured!")
    end)
end

function Result.Ok<T,E>(self: Result<T,E>): T?
    local t = self:Unwrap()
    return t
end


function Result.Err<T,E>(self: Result<T,E>): E?
    local e = select(2, self:Unwrap())
    return e
end


function Result.AndThen<T,E,R>(self: Result<T,E>, _f: (T) -> (R)): (R?,E?)
    local t = self:Ok()
    return t and _f(t) or nil, self:Err()
end


function Result.OrElse<T,E,R>(self: Result<T,E>, _f: (E) -> (R)): (T?,R?)
    local e = self:Err()
    return self:Ok(), e and _f(e) or nil
end


function _new<T,E>(state: boolean, v: T | E)
    local r = setmetatable(
        {Value = {_t = state, v = v} },
        {__index = Result}
    )
    return r
end



return m