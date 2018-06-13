io.stdout:setvbuf("no")
_G.window_width = 1024
_G.window_height = 768
function love.conf(t)
	t.console = false
	t.window.width = _G.window_width
	t.window.height = _G.window_height
end