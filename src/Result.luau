
export type Result<T,E> = {
    Value: {_t: true, v: T} | {_t: false, v: E},
    Unwrap: (Result<T,E>) -> (T?, E?),
    UnwrapOr: (Result<T,E>, _f: (E) -> ()) -> (T?),
    UnwrapOrDefault: (Result<T,E>, _f: (E) -> (T)) -> (T),
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

function m.FromT<T,E>(v: T): Result<T,E> return _new(true, v) end
function m.FromE<T,E>(v: E): Result<T,E> return _new(false, v) end


function _new<T,E>(state: boolean, v: T | E)
    local r = setmetatable(
        {Value = {_t = state, v = v} },
        {__index = m}
    )
    return r
end

return m