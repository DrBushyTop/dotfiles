local eventtap = hs.eventtap
local eventTypes = eventtap.event.types
local keycodes = hs.keycodes.map
local windowFilter = hs.window.filter

local function swapCmdCtrlEventHandler(event)
	local flags = event:getFlags()
	local keycode = event:getKeyCode()

	-- and clauses needed to allow hyper to work
	if flags.cmd and not flags.ctrl then
		flags.cmd = false
		flags.ctrl = true
	elseif flags.ctrl and not flags.cmd then
		flags.ctrl = false
		flags.cmd = true
	end

	if keycode == keycodes.cmd then
		keycode = keycodes.ctrl
	elseif keycode == keycodes.rightcmd then
		keycode = keycodes.rightctrl
	elseif keycode == keycodes.ctrl then
		keycode = keycodes.cmd
	elseif keycode == keycodes.rightctrl then
		keycode = keycodes.rightcmd
	end

	event:setKeyCode(keycode)
	event:setFlags(flags)

	return false
end

local swapCmdCtrlEventTapObj = eventtap.new({
	eventTypes.keyDown,
	eventTypes.keyUp,
	eventTypes.flagsChanged,
}, swapCmdCtrlEventHandler)

TerminalFocusFilter = windowFilter.new("Alacritty"):subscribe({

	[windowFilter.windowFocused] = function()
		print("Focused!")
		swapCmdCtrlEventTapObj:start()
	end,
	[windowFilter.windowUnfocused] = function()
		print("Unfocused!")
		swapCmdCtrlEventTapObj:stop()
	end,
})

TerminalFocusFilter = windowFilter.new("Warp"):subscribe({

	[windowFilter.windowFocused] = function()
		print("Focused!")
		swapCmdCtrlEventTapObj:start()
	end,
	[windowFilter.windowUnfocused] = function()
		print("Unfocused!")
		swapCmdCtrlEventTapObj:stop()
	end,
})
