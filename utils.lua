
function safeIndex(t, ...)
	for _, k in pairs({...}) do
		if type(t) ~= 'table' then return nil end
		t = t[k]
	end
	return t
end

function lerpAngle(a, b, t)
	local theta = b - a
	if theta > math.pi then
		a = a + 2*math.pi
	elseif theta < -math.pi then
		a = a - 2*math.pi
	end
	return lume.lerp(a, b, t)
end

function hash(x)
	local z = math.sin(x)*43758.5453
	return z - math.floor(z)
end

function hash2(x, y)
	local z = math.sin(x*12.9898 + y*78.233)*43758.5453
    return z - math.floor(z)
end

ease = {
	inQuad = function (t) return t*t end,
	outQuad = function (t) return t*(2-t) end,
	inOutQuad = function (t) return t<0.5 and 2*t*t or -1+(4-2*t)*t end,
	inCubic = function (t) return t*t*t end,
	outCubic = function (t) return math.pow(t-1,3)+1 end,
	inOutCubic = function (t) return t<0.5 and 4*t*t*t or (t-1)*(2*t-2)*(2*t-2)+1 end,
	inQuart = function (t) return t*t*t*t end,
	outQuart = function (t) return 1-math.pow(t-1,4) end,
	inOutQuart = function (t) return t<0.5 and 8*math.pow(t,4) or 1-8*math.pow(t-1,4) end,
	inQuint = function (t) return t*t*t*t*t end,
	outQuint = function (t) return 1+math.pow(t-1,5) end,
	inOutQuint = function (t) return t<0.5 and 16*math.pow(t,5) or 1+16*math.pow(t-1,5) end
}

function buildName(name, postfix)
	return name .. (postfix ~= 0 and '(' .. postfix .. ')' or '')
end
