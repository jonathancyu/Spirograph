--[[
TODO:
add text input boxes
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

local radius 			= 200
local radiusInner 		= 115
local lineDist 			= 200
	local k 			= radiusInner/radius
	local l 			= lineDist/radiusInner

local center 			= {x=_G.window_width/2, y=_G.window_height/2}
	local innercircle 	= {x = 0, y = 0}
	local lastx, lasty 	= 0, 0

local endTheta 			= math2.lcm(2, 1, math2.reduce(2*radiusInner, radius - radiusInner)) * math.pi

local drawTime 			= 4
local tick 				= love.timer.getTime
	local theta			= 0
	local done 			= false
	local paused 		= false

local resolution 		= 50
	local t 			= 0
	local fixed_dt 		= 1/60
	local thetaPerFrame = fixed_dt * (endTheta/drawTime)
	local incrementRate = (1/resolution)

	local currentTime 	= tick()
	local accumulator 	= 0

local trace = line.new(center.x, center.y)
local graph  			= {x=center.x - 300, y=_G.window_height - 75}
	graph.sin 			= line.new(graph.x, graph.y)
	graph.cos 			= line.new(graph.x, graph.y)
	graph.mode 			= "sin"

local colorModes = {"distance", "radius", "angle i", "angle ii", "custom", "blank"} 
local colorMode = 4
local colorCycleTimes = 5
local colorDistanceMult = 200
local customColor = color.new(255, 100, 0)
local h, s, v = color.rgbToHsv(customColor.args())
local starth = h
local colors = {}
	for i, name in pairs(colorModes) do
		colors[name] = color.new(0, 0, 0)
	end
	colors["custom"] = customColor
	local colorText = love.graphics.newText(love.graphics.newFont("Roboto.ttf", 20), colorModes[colorMode])

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local live = false
local newRadius = radius
local newRadiusInner = radiusInner
local newLineDist = linedist


local sliders = {}
	sliders.outerRadius = gui.newSlider(10, 220, 
						200, 20, 
						18, 18, 
						color.new(255, 255, 255), color.new(0, 0, 0), 
						radius, 50, 200,  --default, min, max, 
						10, 
						function(self, dt, mx, my)
							newRadius = self.value
							sliders.innerRadius.maxValue = self.value - 10
							sliders.innerRadius.range = sliders.innerRadius.maxValue - sliders.innerRadius.minValue
							sliders.innerRadius.step(dt, mx, my)
							sliders.lineDist.step(dt, mx, my)
						end)
	sliders.innerRadius = gui.newSlider(10, 245, 
						200, 20, 
						18, 18, 
						color.new(255, 255, 255), color.new(0, 0, 0), 
						radiusInner, 11, radius-1,  --default, min, max, 
						10,
						function(self, dt, mx, my)
							newRadiusInner = self.value
						end)

	sliders.lineDist 	= gui.newSlider(10, 270, 
						200, 20, 
						18, 18, 
						color.new(255, 255, 255), color.new(0, 0, 0), 
						lineDist, -200, 200,--radius,  --default, min, max, 
						10, 
						function(self, dt, mx, my)
							newLineDist = self.value
						end)

	sliders.red 		= gui.newSlider(15, _G.window_height - 95, 
						120, 2, 
						6, 16, 
						color.new(255, 255, 255), color.new(255, 0, 0), 
						customColor.r, 0, 254, 
						0, 
						function(self, dt, mx, my)
							customColor.setR(self.value)
							self.sliderColor.setColor(gui.constrain((self.value/self.range)*255, 50, 255), 50, 50)
						end)	

	sliders.green 		= gui.newSlider(15, _G.window_height - 75, 
						120, 2, 
						6, 16, 
						color.new(255, 255, 255), color.new(0, 255, 0), 
						customColor.g, 0, 254, 
						0, 
						function(self, dt, mx, my)
							customColor.setG(self.value)
							self.sliderColor.setColor(50, gui.constrain((self.value/self.range)*255, 50, 255), 50)
						end)	

	sliders.blue 		= gui.newSlider(15, _G.window_height - 55, 
						120, 2, 
						6, 16, 
						color.new(255, 255, 255), color.new(0, 255, 0), 
						customColor.b, 0, 254, 
						0, 
						function(self, dt, mx, my)
							customColor.setB(self.value)
							self.sliderColor.setColor(50, 50, gui.constrain((self.value/self.range)*255, 50, 255), 50)
						end)	

local buttons = {}

	buttons.draw = gui.newButton("DRAW", 7, 305, 120, 40, 
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

			endTheta 		= math2.lcm(2, 1, math2.reduce(2*radiusInner, radius - radiusInner)) * math.pi			
			thetaPerFrame 	= fixed_dt * (endTheta/drawTime)

			h, s, v 		= color.rgbToHsv(customColor.args())
			starth = h

			theta			= 0
			currentTime 	= tick()

			trace.destroy()
			trace = nil
			trace = line.new(center.x, center.y)		

			graph.sin.destroy()
			graph.sin = nil
			graph.sin = line.new(graph.x, graph.y)

			graph.cos.destroy()
			graph.cos = nil
			graph.cos = line.new(graph.x, graph.y)
			done			= false
		end,
		nil, 
		{textColor = color.new(200, 200, 200)}, 0.6)

	buttons.colorLeft = gui.newButton("<", 138, 284, 10, 20, 
		color.new(255, 255, 255), 0, 
		color.new(255, 255, 255), 255,
		"Roboto2.ttf", 20, 
		function(x, y)
			colorMode = (colorMode - 2)%#colorModes + 1
			colorText:set(colorModes[colorMode])
			buttons.colorRight.x = buttons.colorLeft.x + colorText:getWidth() + 32
		end,
		nil, 
		{textColor = color.new(120, 120, 120)}, 0.6)
	buttons.colorRight = gui.newButton(">", buttons.colorLeft.x + colorText:getWidth() + 32, 284, 10, 20, 
		color.new(255, 255, 255), 10, 
		color.new(255, 255, 255), 255,
		"Roboto2.ttf", 20, 
		function(x, y)
			colorMode = (colorMode % #colorModes) + 1
			colorText:set(colorModes[colorMode])
			buttons.colorRight.x = buttons.colorLeft.x + colorText:getWidth() + 32
		end,
		nil, 
		{textColor = color.new(120, 120, 120)}, 0.6)

	buttons.sin = gui.newButton("sin", graph.x - 30, graph.y - 22, 25, 20, 
		color.new(255, 255, 255), 0, 
		color.new(255, 255, 255), 255,
		"Roboto2.ttf", 20, 
		function(x, y)
			graph.mode = "sin"
			buttons.sin.textColor.setColor(255, 255, 255)
			buttons.cos.textColor.setColor(50, 50, 50)
		end)

	buttons.cos = gui.newButton("cos", graph.x - 36, graph.y - 2, 30, 20, 
		color.new(255, 255, 255), 0, 
		color.new(50, 50, 50), 255,
		"Roboto2.ttf", 20, 
		function(x, y)
			graph.mode = "cos"
			buttons.cos.textColor.setColor(255, 255, 255)
			buttons.sin.textColor.setColor(50, 50, 50)
		end)


function love.load()
	love.window.setTitle("Spirograph")
	love.graphics.setBackgroundColor(0, 0, 0)
end

local function updateDrawing()
	local cx = (radius-radiusInner)*math.cos(theta)
	local cy = (radius-radiusInner)*math.sin(theta)
	innercircle.x = cx
	innercircle.y = cy
	local x = ((1-k)*math.cos(theta) + l*k*math.cos(theta*(1-k)/k))
	local y = ((1-k)*math.sin(theta) - l*k*math.sin(theta*(1-k)/k))
		lastx = x
		lasty = y



	colors["distance"].setColor(color.hsvToRgb((starth + (colorCycleTimes*360*(theta/endTheta)))%360, s, v))
	colors["radius"].setColor(color.hsvToRgb((starth + math2.magnitude(center.x, center.y, x, y)*colorDistanceMult)%360, s, v))
	colors["angle i"].setColor(color.hsvToRgb((starth + ((((theta*(1-k)/k)%(2*math.pi))/(2*math.pi))*360))%360, s, v))
	colors["angle ii"].setColor(color.hsvToRgb((starth + ((math.atan2(y, x)*360)/(2*math.pi)))%360, s, v))
	colors["blank"].setColor(255, 255, 255)

	local _colors = {}

	for name, v in pairs(colors) do
		_colors[name] = v()
	end
	_colors["custom"] = colors["custom"]
	trace.add(radius * x, radius * y, {colors = _colors})
	for name, v in pairs(_colors) do
		_colors[name] = v()
	end
	graph.sin.add((theta/endTheta)*600, y*20, {colors = _colors})
	graph.cos.add((theta/endTheta)*600, x*-20, {colors = _colors})

end




function love.update(dt)
	if not love.window.hasFocus() then return end
	local mouseX, mouseY = love.mouse.getX(), love.mouse.getY()

	--button handling
	for name, slider in pairs(sliders) do
		if gui.isInBounds(mouseX, mouseY, slider.x, slider.y, slider.width, slider.height) or
		   gui.isInBounds(mouseX, mouseY, slider.pos - slider.sliderWidth/2, slider.y - slider.sliderHeight/2, slider.sliderWidth, slider.sliderHeight) then
			slider.mouseIsOver = true
		else					
			slider.mouseIsOver = false
		end
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

	--spirograph drawing 
	if not done and not paused then	

		local newTime = tick()
		local frameTime = newTime - currentTime
		currentTime = newTime

		accumulator = accumulator + frameTime

		while (accumulator >= fixed_dt) do
			t = t + fixed_dt
			accumulator = accumulator - fixed_dt

			for i = theta, theta + thetaPerFrame, incrementRate do
				theta = i
				if theta > endTheta then
					theta = endTheta
					updateDrawing()
					done = true
					break
				end
				updateDrawing()
				
			end
		end
	end
end

function love.mousepressed(x, y, button, istouch)
	for name, slider in pairs(sliders) do
		if gui.isInBounds(x, y, slider.x, slider.y, slider.width, slider.height) or
		   gui.isInBounds(x, y, slider.pos - slider.sliderWidth/2, slider.y - slider.sliderHeight/2, slider.sliderWidth, slider.sliderHeight) then
			slider.clicked = true
			slider.step(0, x, y)
		end
	end

	for name, button in pairs(buttons) do
		if button.mouseIsOver then
			button.clicked(x, y)
		end
	end
end

function love.mousereleased(x, y, button, istouch)
	for name, slider in pairs(sliders) do
		slider.clicked = false
	end
end

function love.keypressed(key, scancode, isrepeat)
	if key == "space" then
		if paused == true then
			lasttick = tick()
		end
		paused = not paused
	elseif key == "1" then
		
	end
end

local font = love.graphics.newFont("Roboto.ttf", 20)
local font2 = love.graphics.newFont("Roboto2.ttf", 20)

local function truncate(n)
	return math.floor(n*1000)/1000
end

function love.draw()
	if not done then
		love.graphics.setColor(20, 20, 20)
		love.graphics.circle("line", center.x, center.y, radius*(1-k))

		love.graphics.setColor(255, 255, 255)
		love.graphics.circle("line", center.x + innercircle.x, center.y + innercircle.y, radiusInner, 100)
		love.graphics.circle("line", center.x, center.y, radius, 100)
		love.graphics.line(center.x + innercircle.x, center.y + innercircle.y, center.x + radius*lastx, center.y + radius*lasty)
	end
	for name, slider in pairs(sliders) do
		slider.draw()
	end

	for name, button in pairs(buttons) do
		button.draw()
	end
	

	love.graphics.setColor(0, 0, 0)

	love.graphics.setFont(font)
	love.graphics.print("R", 11, 210)
	love.graphics.print("r", 12, 235)
	love.graphics.print("D", 11, 260)

	love.graphics.setColor(255, 255, 255)

	love.graphics.print(newRadius, 215, 210)
	love.graphics.print(newRadiusInner, 215, 235)
	love.graphics.print(newLineDist, 215, 260)

	love.graphics.setColor(customColor.args())
	love.graphics.print("preview", 14, _G.window_height - 50)
	love.graphics.rectangle("fill", 120, _G.window_height - 45, 15, 15)
	love.graphics.setColor(255, 255, 255)


	love.graphics.print("COLOR MODE", 9, 285)
	love.graphics.setFont(font2)
	love.graphics.setFont(font)
	love.graphics.print(string.upper(colorModes[colorMode]), buttons.colorLeft.x + 12, 285)

	love.graphics.rectangle("fill", graph.x, graph.y, 600, 2)
	--love.graphics.rectangle("fill", gui.constrain(graph.x + (598 * (theta/endTheta)), graph.x, center.x + 298), graph.y, 2, 4)
	love.graphics.print("theta = "..truncate(theta/math.pi).."*pi", graph.x + 604, graph.y - 11)

	--preview	
	local littleR = 100 * (newRadiusInner/newRadius)
	if sliders.outerRadius.mouseIsOver or sliders.outerRadius.clicked then
		love.graphics.line(10, 105, 110, 105)
		love.graphics.print("R", 12, 85)
	end
	if sliders.innerRadius.mouseIsOver or sliders.innerRadius.clicked then
		love.graphics.line(210 - 2*littleR, 105, 210 - littleR, 105)
		love.graphics.print("r", 215-2*littleR, 85)
	end
	if sliders.lineDist.mouseIsOver or sliders.lineDist.clicked then		
		love.graphics.line(210 - littleR, 105, 210-littleR + (newLineDist/newRadius)*100, 105)
		love.graphics.print("D", 210-littleR, 85)
	end

	love.graphics.circle("line", 210 - littleR, 105, littleR, 100)
	love.graphics.circle("line", 110, 105, 100, 100)
	love.graphics.circle("line", 210-littleR + (newLineDist/newRadius)*100, 105, 1, 100)
	for i = 1, #trace.points-1 do
		if trace.points[i].colors[colorModes[colorMode]].args() == nil then
			print(trace.points[i].colors[colorModes[colorMode]].args())
			print(trace.points[i].x, trace.points[i].y)
		end
		love.graphics.setColor(trace.points[i].colors[colorModes[colorMode]].args())
		love.graphics.line(trace.points[i].x, trace.points[i].y,  trace.points[i+1].x, trace.points[i+1].y)
		love.graphics.line(graph[graph.mode].points[i].x, graph[graph.mode].points[i].y,  graph[graph.mode].points[i+1].x, graph[graph.mode].points[i+1].y)
	end
	love.graphics.setColor(255, 255, 255)
	love.graphics.print(tostring(love.timer.getFPS()), _G.window_width - 40, 10)
end