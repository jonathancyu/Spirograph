do

end
-- end testing environment

local line 		= {}

function love.load()
	love.window.setTitle("Spirograph")
	love.graphics.setBackgroundColor(0, 0, 0)
end

--line
do
	function line.new()
		local self = {}
		local points = {}

		function self.draw()
			for i = 1, #points-1 do
				love.graphics.line(points[i].x, points[i].y,  points[i+1].x, points[i+1].y)
			end
		end

		function self.add(x, y)
			table.insert(points, {x=x, y=y})
		end
		return self
	end
end


-- t = 6.2888888888889 
--currently, the problem with this is that aboutSame  thinks things are about the same on basically the first step for slow draws.

--state
local tick = love.timer.getTime
local tickrate = 1/144
local incrementrate = 1/45
local radius = 200
local radiusinner = 120
local linedist = 75
local k = radiusinner/radius
local l = linedist/radiusinner
local center = {x=_G.window_width/2, y=_G.window_height/2}
local t = 0
local trace = line.new()
local otrace = line.new()

do
	local x = 2*math.pi/(1+((1-k)/k))
	print(x)
end

for i = 1, 301 do
	local x = (1-k)*math.cos((i/300)*2*math.pi)
	local y = (1-k)*math.sin((i/300)*2*math.pi)
	otrace.add(center.x + radius * x, center.y + radius * y)
end

local lasttick = tick()

local start = {x = ((1-k) + l*k), y = 0}
local done = false

local innercircle = {x = 0, y = 0}
local lastx, lasty = 0, 0

local function aboutSame(x, y)
	return math.abs(y-x) <= .005
end

local function getTBruteForce()
	local _t = incrementrate
	while true do
		_t = _t + incrementrate
		local x = ((1-k)*math.cos(t) + l*k*math.cos(t*(1-k)/k))
		local y = ((1-k)*math.sin(t) - l*k*math.sin(t*(1-k)/k))
		if aboutSame(x, start.x) and aboutSame(y, start.y) then
			print("done")			
			break
		end
	end
	return _t
end
print(getTBruteForce())
function love.update(dt)
	local current = tick()
	if current-lasttick > tickrate then--and not done then	
		lasttick = lasttick + tickrate	
		t = t + incrementrate
		local cx = (radius-radiusinner)*math.cos(t)
		local cy = (radius-radiusinner)*math.sin(t)
		innercircle.x = cx
		innercircle.y = cy
		local x = ((1-k)*math.cos(t) + l*k*math.cos(t*(1-k)/k))
		local y = ((1-k)*math.sin(t) - l*k*math.sin(t*(1-k)/k))
		lastx = x
		lasty = y
		trace.add(center.x + radius * x, center.y + radius * y)
		--[[if aboutSame(x, start.x) and aboutSame(y, start.y) then
			t = t + incrementrate
			local x2 = ((1-k)*math.cos(t) + l*k*math.cos(t*(1-k)/k))
			local y2 = ((1-k)*math.sin(t) - l*k*math.sin(t*(1-k)/k))
			trace.add(center.x + radius * x2, center.y + radius * y2)
			done = true
			print("DONE", t)
		end]]
		love.update(dt)
	end
end
function love.draw()
	if not done then
		love.graphics.setColor(100, 100, 100)
		otrace.draw()
		love.graphics.setColor(255, 255, 255)
		love.graphics.circle("line", center.x + innercircle.x, center.y + innercircle.y, radiusinner, 100)
		love.graphics.line(center.x + innercircle.x, center.y + innercircle.y, center.x +radius*lastx, center.y + radius*lasty)
	end
	love.graphics.setColor(255, 255, 255)
	trace.draw()
end