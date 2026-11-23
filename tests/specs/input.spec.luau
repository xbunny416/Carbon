--!strict
-- Action map, mobile button layout, camera shake, control bindings and settings validation (step 1.5).
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local csv = require("../../tools/csv")
local Roblox = require("../roblox")
local expect = require("../expect")

local Shared = Roblox.game.ReplicatedStorage.Shared
local Lib = Roblox.game.StarterPlayer.StarterPlayerScripts.Client.Lib
local Config = Roblox.require(Shared.Config)
local Settings = Roblox.require(Shared.Settings)
local ActionMap = Roblox.require(Lib.ActionMap)
local TouchLayout = Roblox.require(Lib.TouchLayout)

local Controls = Config.Controls

-- Landscape phones and tablets (Roblox's default orientation), plus a portrait phone.
local SCREENS = {
	{ 640, 360 },
	{ 667, 375 },
	{ 844, 390 },
	{ 932, 430 },
	{ 1024, 768 },
	{ 1194, 834 },
	{ 1366, 1024 },
	{ 375, 667 },
}

local function isEnumItem(enum: any, name: string): boolean
	return (pcall(function()
		return enum[name]
	end))
end

local function isBindable(name: string): boolean
	if string.sub(name, 1, 11) == "MouseButton" then
		return isEnumItem(roblox.Enum.UserInputType, name)
	end
	return isEnumItem(roblox.Enum.KeyCode, name)
end

local function distance(ax: number, ay: number, bx: number, by: number): number
	return math.sqrt((ax - bx) ^ 2 + (ay - by) ^ 2)
end

return {
	["lookup merges keyboard and gamepad bindings"] = function()
		local lookup = ActionMap.lookup(Controls.Keyboard, Controls.Gamepad)
		expect.equal(lookup.R[1], "Flip")
		expect.equal(lookup.ButtonY[1], "Flip")
		expect.equal(lookup.E[1], "Interact")
		expect.equal(lookup.Space, nil)
	end,
	["an action held by two inputs begins once and ends with the last release"] = function()
		local tracker = ActionMap.newTracker()
		expect.equal(tracker.press("R", "Flip"), true)
		expect.equal(tracker.press("Touch.Flip", "Flip"), false)
		expect.equal(tracker.release("R", "Flip"), false)
		expect.equal(tracker.isDown("Flip"), true)
		expect.equal(tracker.release("Touch.Flip", "Flip"), true)
		expect.equal(tracker.isDown("Flip"), false)
		expect.equal(tracker.release("E", "Interact"), false, "release without press")
	end,
	["shift lock keys are real keys and never steal an action key"] = function()
		local lookup = ActionMap.lookup(Controls.Keyboard)
		for _, key in Controls.Camera.ShiftLockKeys do
			expect.truthy(isEnumItem(roblox.Enum.KeyCode, key), `Shift Lock key {key}`)
			expect.equal(lookup[key], nil, `{key} is both Shift Lock and an action`)
		end
	end,
	["camera zoom range is third person"] = function()
		expect.truthy(Controls.Camera.MinZoom > 0.5 and Controls.Camera.MinZoom < Controls.Camera.MaxZoom, "MinZoom")
	end,
	["touch layouts place known actions, each once, with a gap from the jump button"] = function()
		for name, layout in Controls.Touch.Layouts do
			local seen: { [string]: boolean } = {}
			for _, button in layout do
				expect.truthy(table.find(Controls.Actions, button.Action), `{name}: unknown action {button.Action}`)
				expect.equal(seen[button.Action], nil, `{name}: {button.Action} twice`)
				seen[button.Action] = true
				expect.truthy(button.Distance >= Controls.Touch.Gap, `{name}: {button.Action} touches the jump button`)
				expect.truthy(button.Scale >= 1, `{name}: {button.Action} smaller than the base size`)
			end
		end
	end,
	["settings reject unknown keys, wrong types and out-of-range values"] = function()
		expect.equal(Settings.isValid("CameraShake", false), true)
		expect.equal(Settings.isValid("CameraShake", 0), false)
		expect.equal(Settings.isValid("MusicVolume", 0.3), true)
		expect.equal(Settings.isValid("MusicVolume", 1.5), false)
		expect.equal(Settings.isValid("MusicVolume", 0 / 0), false)
		expect.equal(Settings.isValid("ButtonLayout", "Default"), true)
		expect.equal(Settings.isValid("ButtonLayout", "NoSuchLayout"), false)
		expect.equal(Settings.isValid("Fuel", 1000000), false)
		expect.equal(Settings.isValid("__index", true), false)
	end,
	["input names: KeyCode for keys and gamepads, UserInputType for mouse buttons"] = function()
		expect.equal(ActionMap.inputName("Keyboard", "Q"), "Q")
		expect.equal(ActionMap.inputName("Gamepad1", "ButtonX"), "ButtonX")
		expect.equal(ActionMap.inputName("MouseButton2", "Unknown"), "MouseButton2")
		expect.equal(ActionMap.inputName("MouseMovement", "Unknown"), nil)
		expect.equal(ActionMap.inputName("Touch", "Unknown"), nil)
		expect.equal(ActionMap.inputName("Keyboard", "Unknown"), nil)
	end,
	["preferred input maps to a device"] = function()
		expect.equal(ActionMap.device("KeyboardAndMouse"), "KeyboardAndMouse")
		expect.equal(ActionMap.device("Gamepad"), "Gamepad")
		expect.equal(ActionMap.device("MicroGamepad"), "Gamepad")
		expect.equal(ActionMap.device("Touch"), "Touch")
	end,
	["every action has a keyboard and a gamepad binding, and every binding is a known action"] = function()
		local known: { [string]: boolean } = {}
		for _, action in Controls.Actions do
			known[action] = true
			expect.truthy(Controls.Keyboard[action] and #Controls.Keyboard[action] > 0, `{action} keyboard`)
			expect.truthy(Controls.Gamepad[action] and #Controls.Gamepad[action] > 0, `{action} gamepad`)
		end
		for _, bindings in { Controls.Keyboard, Controls.Gamepad } do
			for action in bindings do
				expect.truthy(known[action], `{action} is not in Controls.Actions`)
			end
		end
	end,
	["every binding names a real KeyCode or mouse button, used by one action only"] = function()
		for _, bindings in { Controls.Keyboard, Controls.Gamepad } do
			local owner: { [string]: string } = {}
			for action, inputs in bindings do
				for _, input in inputs do
					expect.truthy(isBindable(input), `{action}: unknown input {input}`)
					expect.equal(owner[input], nil, `{input} bound twice`)
					owner[input] = action
				end
			end
		end
	end,
	["every action has a label string"] = function()
		local rows = csv.parse(fs.readFile("src/localization/GameStrings.csv"))
		local keys: { [string]: boolean } = {}
		for index = 2, #rows do
			keys[rows[index][1]] = true
		end
		for _, action in Controls.Actions do
			expect.truthy(keys[`Controls.{action}`], `Controls.{action}`)
		end
	end,

	["touch buttons are at least 64 px, on screen and never overlap (all screen sizes)"] = function()
		expect.truthy(Controls.Touch.MinButtonSize >= 64, "bible: touch targets >= 64 px")
		for _, screen in SCREENS do
			local width, height = screen[1], screen[2]
			local jump = TouchLayout.defaultJump(width, height)
			for name, layout in Controls.Touch.Layouts do
				local label = `{name} @ {width}x{height}`
				local placed = TouchLayout.place(width, height, jump, layout, Controls.Touch)
				local gap = TouchLayout.buttonSize(width, height, Controls.Touch) * Controls.Touch.Gap
				expect.equal(#placed, #layout, label)
				for index, a in placed do
					local radius = a.Size / 2
					expect.truthy(a.Size >= Controls.Touch.MinButtonSize, `{label}: {a.Action} size {a.Size}`)
					expect.truthy(
						a.X - radius >= 0 and a.X + radius <= width and a.Y - radius >= 0 and a.Y + radius <= height,
						`{label}: {a.Action} off screen`
					)
					expect.truthy(
						distance(a.X, a.Y, jump.X, jump.Y) >= radius + jump.Radius + gap - 1e-6,
						`{label}: {a.Action} overlaps the jump button`
					)
					for other = index + 1, #placed do
						local b = placed[other]
						expect.truthy(
							distance(a.X, a.Y, b.X, b.Y) >= radius + b.Size / 2 + gap - 1e-6,
							`{label}: {a.Action} overlaps {b.Action}`
						)
					end
				end
			end
		end
	end,
	["button size scales with the screen between the min and max"] = function()
		local touch = Controls.Touch
		expect.equal(TouchLayout.buttonSize(320, 240, touch), touch.MinButtonSize)
		expect.equal(TouchLayout.buttonSize(2560, 1440, touch), touch.MaxButtonSize)
		local mid = TouchLayout.buttonSize(1024, 500, touch)
		expect.near(mid, 500 * touch.ButtonSize, 1e-9)
	end,
	["default jump button matches Roblox's small and large layouts"] = function()
		local small = TouchLayout.defaultJump(844, 390)
		expect.equal(small.Radius, 35)
		expect.equal(small.X, 844 - 60)
		local large = TouchLayout.defaultJump(1024, 768)
		expect.equal(large.Radius, 60)
		expect.equal(large.Y, 768 - 150)
	end,

	["default settings are all valid"] = function()
		for key, value in Config.Data.DefaultSettings :: { [string]: any } do
			expect.truthy(Settings.isValid(key, value), `default {key}`)
		end
	end,
	["every numeric setting has a range"] = function()
		for key, value in Config.Data.DefaultSettings :: { [string]: any } do
			if type(value) == "number" then
				local range = (Config.Data.SettingRanges :: any)[key]
				expect.truthy(range and range.Min <= value and value <= range.Max, `{key} range`)
			end
		end
	end,
}
