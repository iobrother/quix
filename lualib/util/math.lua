local M = {}

function M.floor(n, p)
	if p and p ~= 0 then
		local e = 10 ^ p
		return math.floor(n * e) / e
	else
		return math.floor(n)
	end
end

function M.round(n, p)
	local e = 10 ^ (p or 0)
	return math.floor(n * e + 0.5) / e
end

local randomtable
local tablesize = 97

function M.random(m, n)
	-- 初始化随机数与随机数表，生成97个[0,1)的随机数
	if not randomtable then
		-- 避免种子过小, 生成的随机数序列很相似
		math.randomseed(tonumber(tostring(os.time()):reverse():sub(1,6)))
		randomtable = {}
		for i = 1, tablesize do
			randomtable[i] = math.random()
		end
	end

	local x = math.random()
	local i = 1 + math.floor(tablesize*x)	-- i取值范围[1,97]
	x, randomtable[i] = randomtable[i], x	-- 取x为随机数，同时保证randomtable的动态性

	if not m then
		return x
	elseif not n then
		n = m
		m = 1
	end

	assert(m <= n, "m must be less or equal than n")

	local offset = x*(n-m+1)
	return m + math.floor(offset)
end

return M
