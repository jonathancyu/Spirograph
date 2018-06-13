local gui = {}

function gui.isInBounds(mouseX, mouseY, x, y, width, height)
	return ((mouseX > x and mouseX < x + width) and (mouseY > y and mouseY < y + height))
end

local function tween(start, goal, delta)
	return start + ((goal-start) * delta)
end

function gui.newButton(text, x, y, width, height, _color, alpha, textColor, textAlpha, _font, fontSize, clicked, mouseover, tweens, tweentime, data)
	local self = {
			text = text, 
			x = x, y = y, width = width, height = height, 
			startx = x, starty = y,
			color = _color,
			alpha = alpha,
			delta = 0,
			textColor = textColor,
			textAlpha = textAlpha,
			clicked = clicked, 
			mouseIsOver = false}
	if data then
		for i, v in pairs(data) do
			self[i] = v
		end
	end

	local tweenstarts = {}
	for val, goal in pairs(tweens) do
		tweenstarts[val] = self[val]
	end

	local font = love.graphics.newFont(_font, fontSize)

	function self.draw()
		love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)
		love.graphics.rectangle("fill", self.x, self.y, width, height) -- make text look better
		love.graphics.setColor(self.textColor.r, self.textColor.g, self.textColor.b, self.textAlpha)
		love.graphics.setFont(font)
		love.graphics.print(text, self.x, self.y)
	end

	function self.step(dt, mx, my)
		if self.mouseIsOver then
			if self.delta < 1 then
				self.delta = math.min(self.delta + (dt/tweentime), 1)
			end
		else
			if self.delta > 0 then
				self.delta = math.max(self.delta - (dt/tweentime), 0)
			end
		end
		for val, goal in pairs(tweens) do
			self[val] = tween(tweenstarts[val], goal, self.delta)
		end
	end

	function self.reset()
		self.delta = 0
		for val, goal in pairs(tweens) do
			self[val] = tweenstarts[val]
		end
	end

	return self
end

function gui.constrain(n, min, max)
	if n < min then 
		return min
	elseif n > max then
		return max
	end
	return n
end

local function snap(n)
	local c, f = math.ceil(n), math.floor(n)
	if math.abs(n-c) > math.abs(n-f) then
		return f
	else
		return c
	end
end

function gui.newSlider(x, y, barWidth, barHeight, sliderWidth, sliderHeight, barColor, sliderColor, _font, fontSize, valueColor, defaultValue, minValue, maxValue, padding, step)
	local self = {
		x = x, y = y - (barHeight/2), width = barWidth, height = barHeight,
		value = defaultValue,
		maxValue = maxValue,
		minValue = minValue,
		range = maxValue - minValue,
		clicked = false,
		update = step
	}

	local minPos = x + (padding)
	local maxPos = x + barWidth - padding 
	local posRange = maxPos - minPos
	local pos = padding + (self.range*x + posRange * (defaultValue - self.minValue))/self.range

	local font = love.graphics.newFont(_font, fontSize)

	function self.draw()
		love.graphics.setColor(barColor.args())
		love.graphics.rectangle("fill", self.x, self.y, barWidth, barHeight)
		love.graphics.setColor(sliderColor.args())
		love.graphics.rectangle("fill",
								pos - (sliderWidth/2),
								y - (sliderHeight/2), sliderWidth, sliderHeight)
		love.graphics.setFont(font)
		love.graphics.setColor(valueColor.args())
		love.graphics.print(self.value, self.x + self.width, self.y)
	end

	function self.step(dt, mx, my)
		self:update(dt, mx, my)
		self.value = gui.constrain(self.value, self.minValue, self.maxValue)
		if self.clicked then
			pos = gui.constrain(mx, minPos, maxPos)
			self.value = snap(((pos - x - padding)/(posRange) * self.range) + self.minValue)
		else
			pos = padding + (self.range*x + posRange * (self.value - self.minValue))/self.range
		end
	end

	return self
end


return gui