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
local tickrate = .01/144
local incrementrate = 1/45
local radius = 200
local radiusinner = 132
local linedist = 75
local k = radiusinner/radius
local l = linedist/radiusinner
local center = {x=_G.window_width/2, y=_G.window_height/2}
local t = 0
local trace = line.new()
local otrace = line.new()


for i = 1, 301 do
	local x = (1-k)*math.cos((i/300)*2*math.pi)
	local y = (1-k)*math.sin((i/300)*2*math.pi)
	otrace.add(center.x + radius * x, center.y + radius * y)
end

local lasttick = tick()

local start = {x = ((1-k) + l*k), y = 0}
local done = false

local mult = 2*math.pi

local function primeFactors(n)
	local factors = {} 
	for i = 2, math.floor(math.sqrt(n)) do
		local exp = 0
		while n % i == 0 do
			exp = exp + 1
			n = n/i
		end
		if exp > 0 then 
			factors[i] = exp
		end
	end
	if (n > 1) then
		factors[n] = 1
	end
	return factors
end

local function total(a)
	local result = 1
	for i, exp in pairs(a) do
		result = result * i^exp
	end
	return result
end

local function pfGCD(a, b) -- prime factorization gcd
	local aFactors, bFactors = primeFactors(a), primeFactors(b)
	local commonFactors = {}

	for n, exp in pairs(aFactors) do
		if bFactors[n] then
			local count = 0
			while aFactors[n] > 0 and bFactors[n] > 0 do
				count = count + 1
				aFactors[n] = aFactors[n] - 1
				bFactors[n] = bFactors[n] - 1
			end
			commonFactors[n] = count
		end
	end
	return total(commonFactors)
end

local function pfLCM(a, b) -- prime factorization lcm
	local aFactors, bFactors = primeFactors(a), primeFactors(b)
	local commonFactors = {}

	for n, exp in pairs(aFactors) do
		if bFactors[n] then
			local count = 0
			while aFactors[n] > 0 and bFactors[n] > 0 do
				count = count + 1
				aFactors[n] = aFactors[n] - 1
				bFactors[n] = bFactors[n] - 1
			end
			commonFactors[n] = count
		end
	end
	return total(aFactors) * total(commonFactors) * total(bFactors)
end


local function fgcd(a, b, c, d) -- a/b, c/d
	local nGCD = pfGCD(a, c)
	local dLCM = pfLCM(b, d)

	return nGCD/dLCM
end

local function gcd(a, b)
	while b ~= 0 do
		local t = b
		b = a%b
		a = t
	end
	return a
end
 

local function lcm(a, b, c, d) -- a/b, c/d
	return ((a/b)*(c/d))/fgcd(a, b, c, d)
end

local function reduce(a, b) -- a/b
	local g = gcd(a, b)
	return a/g, b/g
end




local get = lcm(2, 1, reduce(2*radiusinner, radius - radiusinner)) * math.pi

local innercircle = {x = 0, y = 0}
local lastx, lasty = 0, 0

function love.update(dt)
	local current = tick()
	if current-lasttick > tickrate and not done then	
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
		if t > get then
			t = t + incrementrate
			local x2 = ((1-k)*math.cos(t) + l*k*math.cos(t*(1-k)/k))
			local y2 = ((1-k)*math.sin(t) - l*k*math.sin(t*(1-k)/k))
			trace.add(center.x + radius * x2, center.y + radius * y2)
			done = true
			print("DONE", t)
		end
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