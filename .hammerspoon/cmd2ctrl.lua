local eventtap = hs.eventtap
local eventTypes = eventtap.event.types
local keycodes = hs.keycodes.map
local windowFilter = hs.window.filter

local function swapCmdCtrlEventHandler(event)
	local flags = event:getFlags()
	local keycode = event:getKeyCode()

	if flags.cmd then
		flags.cmd = false
		flags.ctrl = true
	elseif flags.ctrl then
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
	eventTypes.flagsChanged,
	eventTypes.keyDown,
	eventTypes.keyUp,
}, swapCmdCtrlEventHandler)

TerminalFocusFilter = windowFilter.new("Terminal"):subscribe({

	[windowFilter.windowFocused] = function()
		swapCmdCtrlEventTapObj:start()
	end,
	[windowFilter.windowUnfocused] = function()
		swapCmdCtrlEventTapObj:stop()
	end,
})
