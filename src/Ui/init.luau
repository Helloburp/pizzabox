local Iris = require(script.Parent.Parent.Packages.Iris)
local C = require(script.Parent["Ui.constants"])
local T = require(script.Parent["Ui.types"])

local Rig = require(script.Rig)
local OC = require(script.OC)

local m = {}


function _menubar(state: T.State)
    Iris.MenuBar()
    do
        Iris.Menu("View")
        Iris.MenuToggle(
            "Rigging", {isChecked = state.WindowStates.Rig}
        )
        Iris.MenuToggle(
            "OC Parts", {isChecked = state.WindowStates.OC}
        )
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
        Iris.RadioButton(
            {"Floor-Poop Brown", "DEFAULT"}, {index = state.Settings.Theme}
        )
        Iris.NextColumn()
        Iris.RadioButton(
            {"Afton Alder", "PURPLE"}, {index = state.Settings.Theme}
        )
        Iris.NextColumn()
        Iris.RadioButton(
            {"Rockin' Red", "RED"}, {index = state.Settings.Theme}
        )
        Iris.NextColumn()
        Iris.RadioButton(
            {"Old but Gold", "GOLD"}, {index = state.Settings.Theme}
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


return m
