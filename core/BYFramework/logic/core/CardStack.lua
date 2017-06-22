local Card = import(".Card")
local CardUtil = import(".CardUtil")
local CardStack = {};

function CardStack:ctor()
	self:reset();
end

function CardStack:dtor()
	self.m_origCardList = nil;
	self.m_curCardMap = nil;
	self.m_perValueCount = nil;
end

function CardStack.createInstanceFromBytes(bytes)
	local instance = new(CardStack);
	instance:initFromBytes(bytes);
	return instance;
end

function CardStack.createInstanceFromCards(cards)
	local instance = new(CardStack);
	instance:initFromCards(cards);
	return instance;
end

function CardStack:initFromBytes(bytes)
	for i,v in ipairs(bytes) do
		local card = Card.new(v);
		self:addCard(card);
		self.m_origCardList[i] = card;
	end
end

function CardStack:initFromCards(cards)
	for i,v in ipairs(cards) do
		self:addCard(v);
		self.m_origCardList[i] = v;
	end
end

local _defaultTable =  {
	__index = function (t,k)
		local v = {};
		rawset(t, k, v);
		return v;
	end
}

local _defaultInt = {
	__index = function (t,k)
		rawset(t, k, 0);
		return 0;
	end	
}

function CardStack:reset()	
	self.m_origCardList = {};
	
	self.m_curCardCount = 0;

	self.m_perValueCount = {};
	setmetatable(self.m_perValueCount, _defaultInt)

	self.m_perCardCount = {};
	setmetatable(self.m_perCardCount, _defaultInt)

	self.m_curCardMap = {};
	setmetatable(self.m_curCardMap, _defaultTable)
end

function CardStack:getOrigCardList()
	return self.m_origCardList;
end

function CardStack:getOrigCardBytes()
	local t = {};
	for i,v in ipairs(self.m_origCardList) do
		t[#t+1] = v.cardByte;
	end
	return t;
end

function CardStack:getCurCardList()
	local t = {};
	for i=3,17 do
		for _,card in ipairs(self.m_curCardMap[i]) do
			t[#t+1] = card;
		end
	end
	return t;
end

function CardStack:getCurCardBytes()
	local t = {};
	for i=3,17 do
		for _,card in ipairs(self.m_curCardMap[i]) do
			t[#t+1] = card.cardByte;
		end
	end
	return t;
end

function CardStack:getCardMap()
	return self.m_curCardMap;
end

function CardStack:getCardCount()
	return self.m_curCardCount;
end

function CardStack:addCards(cards)
	if not cards then
		return;
	end	
	for i,v in ipairs(cards) do
		self:addCard(v);
	end
end

function CardStack:removeCards(cards)
	local t = {};

	for _, v in ipairs(cards) do
		t[v.cardByte] = (t[v.cardByte] or 0) + 1;
	end

	for k,v in pairs(t) do
		if self.m_perCardCount[k] < v then
			return false;
		end
	end

	for k,v in pairs(t) do
		local val = CardUtil.getCardValueFromByte(k);
		assert(#self.m_curCardMap[val] >= v, "remove m_curCardMap error")
		local count = v;
		while count > 0 do
			for i,card in ipairs(self.m_curCardMap[val]) do
				if card.cardByte == k then
					count = count - 1;
					table.remove(self.m_curCardMap[val], i);
					break;
				elseif i == #self.m_curCardMap[val] then
					error("remvoe m_curCardMap error");
				end
			end
		end
		assert(self.m_perCardCount[k] >= v, "remove m_perCardCount error");
		self.m_perCardCount[k] = self.m_perCardCount[k] - v;

		assert(self.m_perValueCount[val] >= v, "remove m_perValueCount error");
		self.m_perValueCount[val] = self.m_perValueCount[val] - v;

		assert(self.m_curCardCount >= v, "remove m_curCardCount error");
		self.m_curCardCount = self.m_curCardCount - v;
	end

	return true;
end

function CardStack:addCard(card)
	local val = card.cardValue;
	table.insert(self.m_curCardMap[val], card);
	self.m_curCardCount = self.m_curCardCount + 1;
	self.m_perValueCount[val] = self.m_perValueCount[val] + 1;
	self.m_perCardCount[card.cardByte] = self.m_perCardCount[card.cardByte] + 1;
end

function CardStack:removeCard(card)
	local val = card.cardValue;

	assert(#self.m_curCardMap[val] > 0, "remove m_curCardMap error")
	for i,v in ipairs(self.m_curCardMap[val]) do
		if v == card then
			table.remove(self.m_curCardMap[val], i);
			break;
		elseif i == #self.m_curCardMap[val] then
			error("remove m_curCardMap error");
		end
	end

	assert(self.m_perCardCount[card.cardByte] > 0, "remove m_perCardCount error");
	self.m_perCardCount[card.cardByte] = self.m_perCardCount[card.cardByte] - 1;

	assert(self.m_perValueCount[val] > 0, "remove m_perValueCount error");
	self.m_perValueCount[val] = self.m_perValueCount[val] - 1;

	assert(self.m_curCardCount > 0, "remove m_curCardCount error");
	self.m_curCardCount = self.m_curCardCount - 1;

	return card;
end

function CardStack:clone()
	local t = CardStack.createInstanceFromCards(self:getCurCardList());
	return t;
end

function CardStack:getMinCardValue()
	for i=3,17 do
		if #self.m_curCardMap[i] > 0 then
			return i;
		end
	end
end

function CardStack:getMaxCardValue()
	for i=17,3,-1 do
		if #self.m_curCardMap[i] > 0 then
			return i;
		end
	end
end

function CardStack:getCardCountByValue(val)
	return #self.m_curCardMap[val];
end

function CardStack:getCardsByValue(val)
	return self.m_curCardMap[val];
end

function CardStack:getPerValueCount()
	return self.m_perValueCount;
end

return CardStack;