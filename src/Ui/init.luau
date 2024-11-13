local Iris = require(script.Parent.Parent.Packages.Iris)
local C = require(script.Parent["Ui.constants"])
local T = require(script.Parent["Ui.types"])

local Rig = require(script.Rig)
local OC = require(script.OC)

local m = {}


function _menubar(state: T.State)
    Iris.MenuBar()
    do
        local function _colorChangeToggle(name: string, value: string)
            local checkedState = Iris.State(state.Settings.Theme:get() == value)
            if Iris.MenuToggle(
                name, {isChecked = checkedState}
            ).checked() then
                state.Settings.Theme:set(value)
            end
            if state.Settings.Theme:get() ~= value then
                checkedState:set(false)
            end
        end
        Iris.Menu("Theme")
        _colorChangeToggle("Poop-Floor Brown", "DEFAULT")
        _colorChangeToggle("Rockin' Red", "RED")
        _colorChangeToggle("Afton Aubergine", "PURPLE")
        _colorChangeToggle("Old but Gold", "GOLD")
        _colorChangeToggle("Remnant Blue", "BLUE")
        Iris.End()
    end
    Iris.End()
end


function _windowContents(state: T.State)
    _menubar(state)
    Iris.SameLine()
    do
        Iris.Group()
        do
            Iris.Text{
                `Welcome to PizzaBox!\n{C.VERSION}`,
                true
            }
        end
        Iris.End()
        do
            Iris.Group()
            Iris.Image{
                C.ICONS.Opened, UDim2.fromOffset(128, 64),
                [Iris.Args.Image.ScaleType] = Enum.ScaleType.Fit
            }
            Iris.End()
        end
    end
    Iris.End()
    Iris.Text("Your one-stop-shop for TPRR utilities.")
    Iris.Separator()
    Iris.Table(2)
    do
        Iris.Checkbox(
            "Rigging", {isChecked = state.WindowStates.Rig}
        )
        Iris.NextColumn()
        Iris.Checkbox(
            "OC Parts", {isChecked = state.WindowStates.OC}
        )
    end
    Iris.End()
end


function _submenus(state: T.State)
    Rig.Cycle(state)
    OC.Cycle(state)
end

function m.FromState(
    state: T.State, _closedCallback: () -> ()
): () -> ()
    return function()
        if Iris.Window(
            "PizzaBox", {isOpened = state.PluginOpenState}
        ).closed() then
            _closedCallback()
        end
        if not state.PluginOpenState:get() then
            Iris.End()
            return
        end
        _windowContents(state)
        Iris.End()

        _submenus(state)
    end
end


function m.Cleanup(state: T.State)
    Rig.Cleanup(state.RigState)
end


return m
