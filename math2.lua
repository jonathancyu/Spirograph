local self = {}

function primeFactors(n)
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
 

function self.lcm(a, b, c, d) -- a/b, c/d
	return ((a/b)*(c/d))/fgcd(a, b, c, d)
end

function self.reduce(a, b) -- a/b
	local g = gcd(a, b)
	return a/g, b/g
end

return self