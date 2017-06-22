local Card = {};

local _typeMap = {
	[1] = "万";
	[2] = "筒";
	[3] = "条";
	[4] = "黑桃";
}

local _valueMap = {
	[1] = "1";
	[2] = "2";
	[3] = "3";
	[4] = "4";
	[5] = "5";
	[6] = "6";
	[7] = "7";
	[8] = "8";
	[9] = "9";
	[10] = "10";
	[11] = "J",
	[12] = "Q",
	[13] = "K",
	[14] = "A",
	[15] = "2",
	[16] = "小王",
	[17] = "大王",
}

local M = {}
	

local mt = {};
mt.__eq = function (c1, c2) 
	return c1.cardByte == c2.cardByte; 
end

mt.__lt = function (c1, c2) 
	if c1.cardValue == c2.cardValue then
		local t1 = c1:getOriginalCard().cardType;
		local t2 = c2:getOriginalCard().cardType;
		return t1 < t2; 
	end
	return c1.cardValue < c2.cardValue; 
end

mt.__le = function (c1, c2) 
	if c1.cardValue == c2.cardValue then
		local t1 = c1:getOriginalCard().cardType;
		local t2 = c2:getOriginalCard().cardType;
		return t2 > t1; 
	end
	return c2.cardValue > c1.cardValue; 
end

mt.__sub = function (c1, c2) 
	return c1.cardValue - c2.cardValue; 
end

mt.__add = function (c1, c2) 
	return c1.cardValue + c2.cardValue; 
end



mt.__tostring = function (t)
	if t.cardValue < 16 then
		return _valueMap[t.cardValue] .. _typeMap[t.cardType];
	else
		return _valueMap[t.cardValue];
	end
end

mt.__index = M;

function Card.new(byte)
	local card = {};
	card.cardByte = byte;
	card.cardType = bit.brshift(byte, 4) + 1;
	card.cardValue = bit.band(byte, 0x0f);

	setmetatable(card, mt);
	if conditions then
		--todo
	end


	return card;
end

return Card;