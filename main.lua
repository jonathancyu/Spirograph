--[[
TODO:
add sliders/text input boxes
figure out how many frames to simulate to satisfy draw time

KNOWN BUGS:
when the window loses focus when it is about to finish you get a stack overflow
]]
local math2 	= require("math2")
local color 	= require("color")
local line 		= require("line")
local gui 		= require("gui")


--------------------------------------------------------------------------------
--variables---------------------------------------------------------------------
--------------------------------------------------------------------------------

local radius 			= 300
local radiusInner 		= 107
local lineDist 			= 300
	local k 			= radiusInner/radius
	local l 			= lineDist/radiusInner

local center 			= {x=_G.window_width/2, y=_G.window_height/2}
	local innercircle 	= {x = 0, y = 0}
	local lastx, lasty 	= 0, 0

local get 				= math2.lcm(2, 1, math2.reduce(2*radiusInner, radius - radiusInner)) * math.pi

local drawTime 			=  5
local tick 				= love.timer.getTime
	local t 			= 0
	local start 		= tick()
	local lasttick 		= tick()
	local done 			= false
	local paused 		= false

local resolution 		= 100
	local tickrate 		= drawTime/(get*resolution)
	local incrementrate = (1/resolution)
	local necessaryTicks= get/tickrate

local trace = line.new()
local otrace = line.new()

local colorModes = {"distance", "radius"} 
local colorMode = 1
local colorCycleTimes = 2
local colorDistanceMult = 200
local c = color.new(255, 0, 255)
local h, s, v = color.rgbToHsv(c.args())
local starth = h

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local live = false
local newRadius = radius
local newRadiusInner = radiusInner
local newLineDist = linedist


local sliders = {}
	sliders.outerRadius = gui.newSlider(10, 20, 
						200, 20, 
						18, 18, 
						color.new(255, 255, 255), color.new(0, 0, 0), 
						"Roboto.ttf", 20, color.new(255, 255, 255),
						radius, 50, 300,  --default, min, max, 
						10, 
						function(self, dt, mx, my)
							newRadius = self.value
							sliders.innerRadius.maxValue = self.value - 10
							sliders.innerRadius.range = sliders.innerRadius.maxValue - sliders.innerRadius.minValue
							sliders.innerRadius.step(dt, mx, my)
							--sliders.lineDist.maxValue = self.value - 2
							sliders.lineDist.step(dt, mx, my)
						end)
	sliders.innerRadius = gui.newSlider(10, 45, 
						200, 20, 
						18, 18, 
						color.new(255, 255, 255), color.new(0, 0, 0), 
						"Roboto.ttf", 20, color.new(255, 255, 255),
						radiusInner, 2, radius-1,  --default, min, max, 
						10,
						function(self, dt, mx, my)
							newRadiusInner = self.value
						end)
	sliders.lineDist 	= gui.newSlider(10, 70, 
						200, 20, 
						18, 18, 
						color.new(255, 255, 255), color.new(0, 0, 0), 
						"Roboto.ttf", 20, color.new(255, 255, 255), 
						lineDist, 1, 300,--radius,  --default, min, max, 
						10, 
						function(self, dt, mx, my)
							newLineDist = self.value
						end)

local buttons = {}
	buttons.color = gui.newButton("", 10, 85, 20, 20, 
		color.new(255, 255, 255), 255,
		color.new(0, 0, 0), 255,
		"Roboto.ttf", 20,
		function(x, y)
			colorMode = (colorMode)%2 + 1
			print(colorMode)
		end,
		nil, 
		{color = color.new(175, 255, 152)}, 0.3)

	buttons.draw = gui.newButton("DRAW", 6, 105, 120, 40, 
		color.new(255, 255, 255), 0, 
		color.new(255, 255, 255), 255,
		"Roboto2.ttf", 40, 
		function(x, y)
			done = true
			innercircle 	= {x = 0, y = 0}
			lastx, lasty 	= 0, 0
			radius 			= newRadius
			radiusInner 	= newRadiusInner
			lineDist 		= newLineDist

			k 				= radiusInner/radius
			l 				= lineDist/radiusInner

			get 			= math2.lcm(2, 1, math2.reduce(2*radiusInner, radius - radiusInner)) * math.pi

			tickrate 		= drawTime/(get*resolution)

			c = color.new(255, 0, 255)
			h, s, v = color.rgbToHsv(c.args())
			starth = h

			t 				= 0
			start 			= tick()
			lasttick 		= tick()
			done			= false
			trace.destroy()
			trace = nil
			trace 			= line.new()		
			otrace.destroy()
			otrace = nil
			otrace = line.new()
				for i = 1, 301 do
					local x = (1-k)*math.cos((i/300)*2*math.pi)
					local y = (1-k)*math.sin((i/300)*2*math.pi)
					otrace.add(center.x + radius * x, center.y + radius * y)
				end	
			necessaryTicks = get/tickrate
			print(necessaryTicks)
		end,
		nil, 
		{textColor = color.new(175, 255, 152)}, 0.6)

function love.load()
	love.window.setTitle("Spirograph")
	love.graphics.setBackgroundColor(0, 0, 0)

	for i = 1, 301 do
		local x = (1-k)*math.cos((i/300)*2*math.pi)
		local y = (1-k)*math.sin((i/300)*2*math.pi)
		otrace.add(center.x + radius * x, center.y + radius * y)
	end
end


function love.update(dt, recursive)
	if not love.window.hasFocus() then return end
	local mouseX, mouseY = love.mouse.getX(), love.mouse.getY()

	--button handling
	if not recursive then
		for name, slider in pairs(sliders) do
			slider.step(dt, mouseX, mouseY)
		end
		for k, button in pairs(buttons) do
			if gui.isInBounds(mouseX, mouseY, button.x, button.y, button.width, button.height)	then
				button.mouseIsOver = true
			else					
				button.mouseIsOver = false
			end
			button.step(dt, mouseX, mouseY)
		end
	end
	local current = tick()

	--spirograph drawing 
	if current-lasttick > tickrate and not done and not paused then	
		local fps = love.timer.getFPS()
		local actualTickRate = 1/fps
		local compensationFrames = actualTickRate/tickrate
		lasttick = lasttick + tickrate	
		if necessaryTicks < 100000 then
			t = t + incrementrate
		else
			for i = 1, 4 do
				love.update(dt, true)
				t = t + incrementrate
			end
			t = t + incrementrate
		end

		local cx = (radius-radiusInner)*math.cos(t)
		local cy = (radius-radiusInner)*math.sin(t)
		innercircle.x = cx
		innercircle.y = cy
		local x = ((1-k)*math.cos(t) + l*k*math.cos(t*(1-k)/k))
		local y = ((1-k)*math.sin(t) - l*k*math.sin(t*(1-k)/k))
			lastx = x
			lasty = y
		local dist = math2.magnitude(center.x, center.y, x, y)
		local segmentColor
		if colorModes[colorMode] == "distance" then
			h = (starth + (colorCycleTimes*360*(t/get)))%360
			c.setColor(color.hsvToRgb(h, s, v))
			segmentColor = c()
		elseif colorModes[colorMode] == "radius" then
			h = (starth + dist*colorDistanceMult)%360
			c.setColor(color.hsvToRgb(h, s, v))
			segmentColor = c()
		end
		trace.add(center.x + radius * x, center.y + radius * y, {color = segmentColor})
		if t > get then
			t = t + incrementrate
			local x2 = ((1-k)*math.cos(t) + l*k*math.cos(t*(1-k)/k))
			local y2 = ((1-k)*math.sin(t) - l*k*math.sin(t*(1-k)/k))
			trace.add(center.x + radius * x2, center.y + radius * y2, {color = c()})
			done = true
			print(string.format("Drawn in %f seconds", tick()-start))
		end
		if necessaryTicks < 100000 then
			love.update(dt)
		end
	end
end

function love.mousepressed(x, y, button, istouch)
	for name, slider in pairs(sliders) do
		if gui.isInBounds(x, y, slider.x, slider.y, slider.width, slider.height) then
			slider.clicked = true
			slider.step(0, x, y)
		end
	end
end

function love.mousereleased(x, y, button, istouch)
	for name, slider in pairs(sliders) do
		slider.clicked = false
	end

	for name, button in pairs(buttons) do
		if button.mouseIsOver then
			button.clicked(x, y)
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then
		if paused == true then
			lasttick = tick()
		end
		paused = not paused
	end
end

local font = love.graphics.newFont("Roboto.ttf", 20)

function love.draw()
	if not done then
		love.graphics.setColor(100, 100, 100)
		otrace.draw()
		love.graphics.setColor(255, 255, 255)
		love.graphics.circle("line", center.x + innercircle.x, center.y + innercircle.y, radiusInner, 100)
		love.graphics.line(center.x + innercircle.x, center.y + innercircle.y, center.x + radius*lastx, center.y + radius*lasty)
	end
	for i = 1, #trace.points-1 do
		love.graphics.setColor(trace.points[i].color.args())
		love.graphics.line(trace.points[i].x, trace.points[i].y,  trace.points[i+1].x, trace.points[i+1].y)
	end

	for name, slider in pairs(sliders) do
		slider.draw()
	end

	for name, button in pairs(buttons) do
		button.draw()
	end

	love.graphics.setColor(0, 0, 0)

	love.graphics.setFont(font)
	love.graphics.print("RADIUS", 11, 10)
	love.graphics.print("INNER RADIUS", 11, 35)
	love.graphics.print("LINE DISTANCE", 11, 60)

	love.graphics.print(colorMode-1, 14, 85) -- tables index at 0, lua

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("COLOR MODE", 35, 85)


	love.graphics.rectangle("fill", center.x - 300, _G.window_height - 30, 600, 2)
	love.graphics.rectangle("fill", center.x - 300, _G.window_height - 34, 2, 4)
	love.graphics.rectangle("fill", center.x + 298, _G.window_height - 34, 2, 4)
	love.graphics.rectangle("fill", gui.constrain(center.x - 300 + (598 * (t/get)), center.x - 300, center.x + 298), _G.window_height - 34, 2, 4)


end