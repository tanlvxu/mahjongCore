local TableUtil = import(".TableUtil")
local Card = import(".Card")
local CardUtil = {};

function CardUtil.checkDoubleJkrbKill(cfg, curCardStack, preCardStack)
	if cfg.DOUBLE_JKRB_KILL and preCardStack then
		local n1 = preCardStack:getCardCountByValue(17);
		local n2 = curCardStack:getCardCountByValue(17);
		return n1 > 0 and n1 <= n2 / 2;
	end
end

function CardUtil.checkTripleTwoKill(cfg, curCardStack, preCardStack)
	if cfg.TRIPLE_TWO_KILL and preCardStack then
		local n1 = preCardStack:getCardCountByValue(17);
		local n2 = curCardStack:getCardCountByValue(15);
		return n1 > 0 and n1 <= n2 / 3;
	end
end

function CardUtil.checkGouJi(cfg, curCardStack, minValue, maxValue)
	minValue = minValue or curCardStack:getMinCardValue();
	maxValue = maxValue or curCardStack:getMaxCardValue();
	
	local gjCards = cfg.GJCARDS;
	if maxValue > 15 then
		return gjCards[maxValue];
	end

	if gjCards[minValue] then
		local cardMap = curCardStack:getCardMap();
		local num = #cardMap[minValue];
		local num_2 = #cardMap[15];
		if minValue < 15 and cfg.GUACARDS[15] and num_2 > 0 then
			num = num + num_2;
		end
		return num >= gjCards[minValue];
	end
end

function CardUtil.checkKaiDian(cfg, curCardStack, minValue, maxValue)
	minValue = minValue or curCardStack:getMinCardValue();
	maxValue = maxValue or curCardStack:getMaxCardValue();
	if minValue ~= maxValue then
		return false;
	end
	local kdCards = cfg.KDCARDS;
	if kdCards[minValue] and kdCards[minValue] <= curCardStack:getCardCountByValue(minValue) then
		return true;
	end
end

function CardUtil.getCardType(cfg, curCardStack, preCardStack)
	if not curCardStack or curCardStack:getCardCount() == 0 then
		return g_GameConst.CARDTYPE.ERROR;
	end

	local curCardMap = curCardStack:getCardMap();

	local minValue = curCardStack:getMinCardValue();

	for i = minValue+1, 14 do
		if #curCardMap[i] > 0 then
			return g_GameConst.CARDTYPE.ERROR;
		end
	end

	local result = g_GameConst.CARDTYPE.NORMAL;
	
	local maxValue = curCardStack:getMaxCardValue();

	if #curCardMap[17] > 0 then
		result = bit.bor(result, g_GameConst.CARDTYPE.WITH_JKRB);
	end

	if #curCardMap[16] > 0 then
		result = bit.bor(result, g_GameConst.CARDTYPE.WITH_JKRS);
	end

	local guaCards = cfg.GUACARDS;
	if #curCardMap[15] > 0 then
		local isTripleTwoKill = CardUtil.checkTripleTwoKill(cfg, curCardStack, preCardStack);
		if minValue < 15 then
			if not guaCards[15] and not isTripleTwoKill then
				return g_GameConst.CARDTYPE.ERROR;
			end
			result = bit.bor(result, g_GameConst.CARDTYPE.WITH_TWO);
		end
		if isTripleTwoKill then
			result = bit.bor(result, g_GameConst.CARDTYPE.TRIPLE_TWO_KILL);
		end		
	end

	if CardUtil.checkGouJi(cfg, curCardStack, minValue, maxValue) then
		result = bit.bor(result, g_GameConst.CARDTYPE.GOU_JI);
	end

	if CardUtil.checkKaiDian(cfg, curCardStack, minValue, maxValue) then
		result = bit.bor(result, g_GameConst.CARDTYPE.KAI_DIAN);
	end

	if CardUtil.checkDoubleJkrbKill(cfg, curCardStack, preCardStack) then
		result = bit.bor(result, g_GameConst.CARDTYPE.DOUBLE_JKRB_KILL);
	end

	return result;
end

---洗牌
function CardUtil.dealCards(cards)
	local total = #cards;
	local mod = math.fmod(total, 6);
	local avr = total/6;
	local max = math.ceil(avr);
	local min = math.floor(avr);

	local info = {}
	local dealCount = 0;
	for i = 1,6 do 
		info[i] = {};

		local count = i <= mod and max or min;
		for j = 1, count do
			info[i][j] = cards[dealCount + j];
		end

		dealCount = dealCount + count;
	end

	return info;
end

function CardUtil.convertBytesToCards(bytes)
	if not bytes then
		return;
	end
	local t = {}
	for i, v in ipairs( bytes ) do
		t[i] = Card.new(v);
	end
	return t;
end

function CardUtil.convertCardsToBytes(cards)
	if not cards then
		return;
	end
	local t = {}
	for i, v in ipairs( cards ) do
		t[i] = v.cardByte;
	end
	return t;
end

function CardUtil.isContainByBit(b1, b2)
    if b1 and b2 then 
        return bit.band(b1, b2) == b2;
    end
    return false;
end

function CardUtil.getCardStackPower(cfg, cardStack)
	local power = 0;
	local kdFlag = false;
	for i=5,17 do
		local count = cardStack:getCardCountByValue(i);
		if count > 0 then
			power = power + cfg.CARD_POWER[i] * count;
			if cfg.KDCARDS[i] and cfg.KDCARDS[i] <= count then
				power = power + 1 * math.floor(count / cfg.KDCARDS[i]);
				kdFlag = true;
			end
		end
	end

	if not kdFlag then
		power = power - 5;
	end

	local num_3 = cardStack:getCardCountByValue(3);
	if num_3 == 0 then
		power = power - 3 
	elseif num_3 == 1 then
		power = power + 0.5;
	else
		power = power + 3*(num_3-1) + 0.5
	end

	local num_4 = cardStack:getCardCountByValue(4);
	if num_4 == 0 then
		power = power - 1.5;
	elseif num_4 == 1 then
		power = power + 0.5;
	else
		power = power + 1.5*(num_4-1) + 0.5
	end

	return power;
end

function CardUtil.getOriginalCardByte(byte)
	if byte > 0x50 then
		return byte - 0x50;
	end
	return byte;
end

function CardUtil.getTributeCardByte(byte)
	if byte < 0x50 then
		return byte + 0x50;
	end
	return byte;
end

function CardUtil.getCardValueFromByte(byte)	
	assert(byte >= 0x01 and byte <= 0x9F, "invalid card byte : "..byte)
	local val = bit.band(byte, 0x0f);
	if val < 3 then
		return val + 13;
	elseif val > 13 then
		return val + 2;
	end
	return val;
end

return CardUtil;