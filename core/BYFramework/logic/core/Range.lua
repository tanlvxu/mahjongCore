local Range = {};

function Range.create(from, to)
	if from > to then
		from, to = to, from;
	end
	local t = {};
	t.from = from;
	t.to = to;
	return t;
end

function Range.contains(range, i)
	return i >= range.from and i <= range.to;
end

return Range;