local color = {}

function color.new(_r, _g, _b)
	local self = {r = _r, g = _g, b = _b, __type = "color"}

	function self.setColor(r, g, b)
		self.r = r
		self.g = g
		self.b = b
	end

	function self.setR(r)
		self.r = r
	end

	function self.setG(g)
		self.g = g
	end

	function self.setB(b)
		self.b = b
	end

	function self.args()
		return self.r, self.g, self.b
	end

	function self.print()
		print(self.r, self.g, self.b)
	end

	return setmetatable(self, {
			__mul = function(a, b)			
				if type(b) == "number" then
					return color.new(a.r*b, a.g*b, a.b*b)
				else
					return color.new(b.r*a, b.g*a, b.b*a)
				end
			end,
			__div = function(a, b)			
				if type(b) == "number" then
					return color.new(a.r/b, a.g/b, a.b/b)
				else
					return color.new(b.r/a, b.g/a, b.b/a)
				end
			end,
			__add = function(a, b)
				return color.new(a.r + b.r, a.g + b.g, a.b + b.b)
			end,
			__sub = function(a, b)
				return color.new(a.r - b.r, a.g - b.g, a.b - b.b)
			end,
			__unm = function(a)
				return color.new(-a.r, -a.g, -a.b)
			end,
			__call = function(a) -- clone
				return color.new(a.r, a.g, a.b)
			end
		})
end

function color.rgbToHsv(r, g, b)
	local V = math.max(r, g, b)
	local min = math.min(r, g, b)

	local c = V - min

	local H
	if c == 0 then
		H = 0
	elseif V == r then
		H = ((g - b)/c)%6
	elseif V == g then
		H = (b - r)/c + 2
	else
		H = (r - g)/c + 4
	end
	H = (H * 60)%360

	local S
	if V == 0 then
		S = 0
	else 
		S = c/V
	end
	return H, S, V
end

function color.hsvToRgb(H, S, V)
	local r, g, b

	local c = V * S
	H = H/60
	local x = c * (1 - math.abs((H%2) - 1))
	if H >= 0 and H <= 1 then
		r, g, b = c, x, 0
	elseif H > 1 and H <= 2 then
		r, g, b = x, c, 0
	elseif H > 2 and H <= 3 then
		r, g, b = 0, c, x
	elseif H > 3 and H <= 4 then
		r, g, b = 0, x, c
	elseif H > 4 and H <= 5 then
		r, g, b = x, 0, c
	elseif H > 5 and H < 6 then
		r, g, b = c, 0, x
	else
		r, g, b = 0, 0, 0
	end
	return r, g, b
end

return color