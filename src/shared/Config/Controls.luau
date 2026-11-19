--!strict
--[[
	Input bindings, the touch button arc and the camera.
	Binding names are Enum.KeyCode names, or Enum.UserInputType names for mouse buttons ("MouseButton1").
	Jump and movement stay on Roblox's default controls (Space / A / the touch jump button and thumbstick).
	A new action needs a keyboard and a gamepad binding, a "Controls.<Action>" string in GameStrings.csv, and a touch
	button in Touch.Layouts if mobile players use it (tests/specs/input.spec.luau checks sizes and overlaps).
]]
type Bindings = { [string]: { string } }

export type TouchButton = {
	Action: string,
	Angle: number, -- degrees around the jump button's center: 90 = straight above, 180 = straight left
	Distance: number, -- gap from the jump button's edge to this button's edge, in base button sizes
	Scale: number, -- size relative to the base button size
}

type ControlsConfig = {
	Actions: { string },
	Keyboard: Bindings,
	Gamepad: Bindings,
	Touch: {
		MinButtonSize: number,
		ButtonSize: number,
		MaxButtonSize: number,
		Gap: number,
		Layouts: { [string]: { TouchButton } },
	},
	Prompts: { Keyboard: string, Gamepad: string, MaxDistance: number },
	Camera: { MinZoom: number, MaxZoom: number, ShiftLockAllowed: boolean, ShiftLockKeys: { string } },
}

local Controls: ControlsConfig = {
	-- Every action the game listens for. Each one needs a keyboard and a gamepad binding. Driving itself uses
	-- Roblox's vehicle controls (W A S D / arrows, gamepad triggers + left stick, touch thumbstick).
	Actions = { "Flip", "Interact", "Menu" },
	Keyboard = {
		Flip = { "R" }, -- turn an upside-down car back over
		Interact = { "E" }, -- walk-up prompts; gets you out of your car while driving
		Menu = { "M" },
	},
	Gamepad = {
		Flip = { "ButtonY" },
		Interact = { "ButtonB" },
		-- Not Select / Start: Roblox keeps those for its own menu and UI navigation.
		Menu = { "DPadUp" },
	},
	Touch = {
		MinButtonSize = 64, -- pixels; no touch button is ever smaller
		ButtonSize = 0.17, -- base button size as a fraction of the screen's shorter side...
		MaxButtonSize = 104, -- ...capped in pixels so tablet buttons stay thumb-sized
		Gap = 0.15, -- minimum space between buttons, in base button sizes
		-- Bottom-right arc around Roblox's jump button. Settings > Button Layout picks one by name. CarController
		-- shows Interact (labelled Get out) only while you drive and Flip only while your car is upside down.
		Layouts = {
			Default = {
				{ Action = "Interact", Angle = 180, Distance = 0.2, Scale = 1.15 },
				{ Action = "Flip", Angle = 95, Distance = 0.25, Scale = 1 },
			},
		},
	},
	-- Walk-up ProximityPrompts: keys and range (studs). Touch taps the prompt.
	Prompts = { Keyboard = "E", Gamepad = "ButtonB", MaxDistance = 12 },
	Camera = {
		MinZoom = 8,
		MaxZoom = 30,
		ShiftLockAllowed = true,
		ShiftLockKeys = { "LeftShift", "RightShift" },
	},
}

return Controls
