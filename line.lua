local line = {}

function line.new(x, y)
	local self = {points = {}}
	
	local pos = {x=x or 0, y=y or 0}

	function self.draw()
		for i = 1, #self.points-1 do
			love.graphics.line(self.points[i].x, self.points[i].y,  self.points[i+1].x, self.points[i+1].y)
		end
	end

	function self.add(x, y, vals)
		local segment = {x=pos.x + x, y=pos.y + y}
		if vals then 
			for i, v in pairs(vals) do
				segment[i] = v
			end
		end
		table.insert(self.points, segment)
	end

	function self.destroy()
		for i = #self.points, 1 do
			table.remove(self, i)
		end
	end
	return self
end

return line