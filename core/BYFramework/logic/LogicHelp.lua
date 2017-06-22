--- a LogicHelp module
-- @module LogicHelp
local CardUtil = import(".core.CardUtil");
local PlayHelp = import(".core.PlayHelp");
local TableUtil = import(".core.TableUtil");
local CardStack = import(".core.CardStack");
local LogicHelp = class("LogicHelp",CommonGameLogic)

function LogicHelp:ctor()

end

function LogicHelp:dtor()
	-- body
end

function LogicHelp:init(data)
	Log.v("LogicHelp:init")
	self.m_tableData = data;

	local mt = getmetatable(self);
	local __index = mt and mt.__index;
	setmetatable(self, {
		__index = function (t, k)
			local v = nil;
			if type(__index) == "function" then
				v = __index(t, k);
				if v then return v; end
			elseif type(__index) == "table" then
				v = __index[k];
				if v then return v; end
			end
			return self.m_tableData[k];
		end;

		__newindex = function (t, k, v)
			self.m_tableData[k] = v;
		end
	})
end

function LogicHelp:checkPlayCards(user, curCardStack, preCardStack)
	local cardType = CardUtil.getCardType(self.playCfg, curCardStack, preCardStack);
	Log.v("LogicHelp:checkPlayCards, cardType", cardType)

	if cardType == g_GameConst.CARDTYPE.ERROR then
		return false, g_CmdCode.PLAY_CARD_ERR_INVALID_CARDS;
	end

	local userCardStack = user.cards;
	local curCardMap = curCardStack:getCardMap();

	local num3 = #curCardMap[3];
	if num3 > 0 then
		if num3 < userCardStack:getCardCountByValue(3) then --拆3
			return false, g_CmdCode.PLAY_CARD_ERR_DIV_3;
		end
		if num3 < curCardStack:getCardCount() then --3挂牌
			return false, g_CmdCode.PLAY_CARD_ERR_MIX_3;
		end
		if num3 < userCardStack:getCardCount() then --不是最后一张3
			return false, g_CmdCode.PLAY_CARD_ERR_PLAY_3;
		end
	end

	local num4 = #curCardMap[4];
	if num4 > 0 then
		if not self:canUserPlay4(user) then
			return false, g_CmdCode.PLAY_CARD_ERR_PLAY_4;
		end
		if num4 < curCardStack:getCardCount() then --4挂牌
			return false, g_CmdCode.PLAY_CARD_ERR_MIX_4;
		end
		if num4 < userCardStack:getCardCountByValue(4) and not self:canDiv4() then --拆4
			return false, g_CmdCode.PLAY_CARD_ERR_DIV_4;
		end
	end

	if user.nShaoStat == g_GameConst.SHAOSTAT.SUCC then
		if #curCardMap[3] == 0 and #curCardMap[16] == 0 and #curCardMap[17] == 0 then
			return false, g_CmdCode.PLAY_CARD_ERR_SHAO_NO_KING;
		end
	end

	if user.nRevoStat == g_GameConst.REVOSTAT.YES then
		if not CardUtil.isContainByBit(cardType, g_GameConst.CARDTYPE.KAI_DIAN) then
			return false, g_CmdCode.PLAY_CARD_ERR_REVO_NO_GOUJI;
		end
	end

	if not PlayHelp.compareCards(self.playCfg, curCardStack, preCardStack) then
		Log.i("LogicHelp:compareCards fail", curCardStack:getCurCardList(), preCardStack:getCurCardList());
		return false, g_CmdCode.PLAY_CARD_ERR_SMALL_CARDS;
	end

	if not userCardStack:removeCards(curCardStack:getOrigCardList()) then
		Log.i("error in LogicHelp:removeCards, curCardStack", curCardStack);
		Log.i("error in LogicHelp:removeCards, userCardStack", userCardStack);
		return false, g_CmdCode.PLAY_CARD_ERR_REMOVE_CARDS;
	end

	if CardUtil.isContainByBit(cardType, g_GameConst.CARDTYPE.DOUBLE_JKRB_KILL) then
		self:setFactor(self.nFactor * 2);
	end

	if CardUtil.isContainByBit(cardType, g_GameConst.CARDTYPE.TRIPLE_TWO_KILL) then
		self:setFactor(self.nFactor * 2);
	end

	return true, cardType;
end

function LogicHelp:checkAIPlayCards(user, curCardStack)
    local userCardStack = user.cards;
    local curCardMap = curCardStack:getCardMap();    
    local num4 = #curCardMap[4];
    if num4 > 0 then
        if not self:canUserPlay4(user) then
            return false;
        end
        if num4 < curCardStack:getCardCount() then --4挂牌
            return false;
        end
        if num4 < userCardStack:getCardCountByValue(4) and not self:canDiv4() then --拆4
            return false;
        end
    end
    return true;
end

function LogicHelp:getPlayCardsToFollowCards(srcCardStack, cards)
	Log.v("LogicHelp:getPlayCardsToFollowCards")
	local t = {};
    for i,v in ipairs(cards) do
    	local preCardStack = CardStack.createInstanceFromCards(v);
    	local srcCardCount = srcCardStack:getPerValueCount(); 
        local values = PlayHelp.getFollowPlayCardsByValue(self.playCfg, srcCardCount, preCardStack);
        if not values then
            return false, v;
        end
        local cards = PlayHelp.selectCardsWithValues(srcCardStack, values);
        srcCardStack:removeCards(cards);
        t[#t+1] = cards;
    end
	return true, t;
end

function LogicHelp:dealCards()
	Log.v("LogicHelp:dealCards");
	local cards;
	if self.m_table.m_localConf.nBuildCard == 1 then
		cards = self.m_table:getBuildCards();
	end
	if not cards then
		cards = TableUtil.randomList(self.playCfg.CARDS);
	end
	return CardUtil.dealCards(cards);
end

function LogicHelp:getCardType(curCardStack, preCardStack)
	return CardUtil.getCardType(self.playCfg, curCardStack, preCardStack);
end

function LogicHelp:updateUserXuanStat(user)
	local faceUser = self.userMgr:getFaceUserByUser(user);
	local result = TableUtil.getValue(self.playCfg.XUAN_RESULT, user.nDianStat, faceUser.nDianStat);
	if not result then
		if user.nXuanStat == g_GameConst.XUANSTAT.OPEN then
			user.nXuanStat = g_GameConst.XUANSTAT.OPEN_FAIL;
			return;
		end
		if user.nXuanStat == g_GameConst.XUANSTAT.SECRET then
			user.nXuanStat = g_GameConst.XUANSTAT.SECRET_FAIL;
			return;
		end
	end
end

function LogicHelp:canUserPlay4(user)
	if self.playCfg.MEN_4 then
		return self.rankList[1] or user.nDianStat == g_GameConst.DIANSTAT.SUCC;
	end
	return true;
end

function LogicHelp:canDiv4()
	if self.playCfg.DIV4_AFTER_LEFT4 then
		return self.isLeft4;
	end
	return true;
end

function LogicHelp:canGameKaiDian()
	if self.isLeft4 then
		return false;
	end

	if self.playCfg.DIAN_BEFORE_FIRST and self.rankList[1] then
		return false;
	end

	return true;
end

function LogicHelp:canUserKaiDian(user, calcCards)
	if user.nRank ~= 0 or user.nDianStat ~= g_GameConst.DIANSTAT.DEFAULT then
		return false;
	end

	if not self:canGameKaiDian() then
		return false;
	end

	if not self:isUserYouTou(user) then
		return false;
	end

	if not calcCards then
		return true;
	end

	local cards = user.cards;
	if cards:getCardCountByValue(4) == 0 then
		return false;
	end

	local t = TableUtil.selectElement(self.playCfg.KDCARDS, function (k,v)
		return cards:getCardCountByValue(k) >= v;
	end, true)
	return t;
end

function LogicHelp:canUserPlayCard(user)
	Log.v("LogicHelp:canUserPlayCard", user.nUserId, user.nRank, user.isMen, user.nPlayStat);
	if user.nRank ~= 0 then
		return false;
	end

	if user.isMen then
		return false;
	end

	return user.nPlayStat ~= g_GameConst.PLAYSTAT.PASS;
end

function LogicHelp:isUserYouTou(user)
	local faceUser = self.userMgr:getFaceUserByUser(user);
	if faceUser.nRank == 0 then
		return true;
	end
	if faceUser.isMen and self.playCfg.MEN_RESULT.isYouTou then
		return true;
	end
	return false;
end

function LogicHelp:canUserRevo(user)
	for i = 15, 17 do
		if user.cards:getCardCountByValue(i) > 0 then
			return false;
		end
	end
	return true;
end

function LogicHelp:getCanBuyCardUsers(value)
	local info = self.playCfg.BUY_CARD[value];
	if not info then
		return;
	end
	local list = TableUtil.selectValues(self.userList, function(i,v)
		return self:canUserBuyCard(v, value);
	end)
	return list;
end

function LogicHelp:canUserBuyCard(user, val)
    local cardMap = user.cards:getCardMap();
    if #cardMap[val] > 0 then
        return false, g_CmdCode.BUY_CARD_ERR_HAVE_CARD;
    end
	local info = self.playCfg.BUY_CARD[val];
	if not info then
		return false, g_CmdCode.BUY_CARD_ERR_INVALID_CARD;
	end
    if info.isFree then
        return true;
    end
    local _,v = TableUtil.selectValue(info.cardOrder, function (i,v)
    	return #cardMap[v] > 0;
    end)
   	if not v then
   		return false, g_CmdCode.BUY_CARD_ERR_NO_MONEY;
   	end
   	return true;
end

function LogicHelp:buyCardForUser(buyUser, value)
	Log.v("LogicHelp:buyCard", buyUser.nUserId, value)
	local info = self.playCfg.BUY_CARD[value];
	assert( info, "invalid buy card value : "..value );

	local sellUser, sellCard;
	for _,v in ipairs(info.seatOrder) do
		local user = self.userMgr:getOffsetUserByUser(buyUser, v);
		local cards = user.cards:getCardsByValue(value);
		if #cards > 1 then
			sellUser = user;
			sellCard = cards[1];
			break;
		end
	end

	assert(sellCard, "not one have extra card : "..value);
	local moneyCard = self:getMoneyCardForUser(buyUser, value);

	if not moneyCard and not info.isFree then
		return false, g_CmdCode.BUY_CARD_ERR_NO_MONEY;
	end

	buyUser.cards:addCard(sellCard);
	sellUser.cards:removeCard(sellCard);

	if moneyCard then
		buyUser.cards:removeCard(moneyCard);

		moneyCard = moneyCard:getTributeCard();
		sellUser.cards:addCard(moneyCard);
	end
	
	local t = {};
	t.buyUid = buyUser.nUserId;
	t.sellUid = sellUser.nUserId;
	t.sellCard = sellCard.cardByte;
	t.moneyCard = moneyCard and moneyCard.cardByte or 0;		
	table.insert(self.buyCardInfo[value], t);	
	return t;
end

function LogicHelp:getCanRevoUsers()
	local list = TableUtil.selectValues(self.userList, function(i,v)
		return self:canUserRevo(v);
	end)
	return list;
end

function LogicHelp:getPlayOpcode(round, user)
	Log.v("LogicHelp:getPlayOpcode", user.nUserId, user.nShaoStat, user.nRevoStat)
	local record = round:getLastRecord(g_CmdCode.PLAY_OP_CALL);
	--新一轮只给出牌选项
	if not record then
		return g_CmdCode.PLAY_OP_CALL;
	end
	--处于烧牌，革命状态的玩家给出牌选项
	if user.nShaoStat == g_GameConst.SHAOSTAT.YES  or user.nRevoStat == g_GameConst.REVOSTAT.YES  then
		return g_CmdCode.PLAY_OP_CALL;
	end
	local opt =  bit.bor(g_CmdCode.PLAY_OP_PASS, g_CmdCode.PLAY_OP_CALL);
	local faceUser = self.userMgr:getFaceUserByUser(user);
	if faceUser.nRevoStat == g_GameConst.REVOSTAT.YES then
		return opt;
	end
	if self.isLeft4 then
		return opt;
	end
	if not self:isUserYouTou(user) then
		return opt;
	end
	if user.nPlayStat ~= g_GameConst.PLAYSTAT.DEFAULT then
		return opt;
	end
	local faceUser = self.userMgr:getFaceUserByUser(user);		
	if faceUser == record.user then
		opt = bit.bor(opt, g_CmdCode.PLAY_OP_CHECK);
	end
	return opt;
end

function LogicHelp:getPlayCardsForUser(user, lastRecord)
	Log.v("LogicHelp:getPlayCardsForUser", user.nUserId);
	if not lastRecord then
		return self:getFirstPlayCardsForUser(user);
	end

	local isShao = user.nShaoStat == g_GameConst.SHAOSTAT.YES;
	local isRevo = user.nRevoStat == g_GameConst.REVOSTAT.YES;
	if not user.bAI and not user.bRobot and not isShao and not isRevo then
		return;
	end

	local lastUser = lastRecord.user;
	local lastCardStack = lastRecord.cardStack;
	local isPartner = self.userMgr:isPartner(user, lastUser);
	if not isShao and self:shouldPassBefore(isPartner, user, lastUser, lastCardStack) then
		return;
	end

	local cards = self:getFollowPlayCardsForUser(user, lastCardStack);
	if not cards or #cards == 0 then
		return;
	end

	local cardStack = CardStack.createInstanceFromCards(cards);
	if not isShao and self:shouldPassAfter(isPartner, user, cardStack, lastUser, lastCardStack) then
		return;
	end

	return cards;
end

function LogicHelp:shouldPassBefore(isPartner, curUser, preUser, preCardStack)
	if isPartner then
		return self:shouldPassPartnerBefore(curUser, preUser, preCardStack);
	else
		return self:shouldPassOppoBefore(curUser, preUser, preCardStack);
	end
end

function LogicHelp:shouldPassAfter(isPartner, curUser, curCardStack, preUser, preCardStack)
	if isPartner then
		return self:shouldPassPartnerAfter(curUser, curCardStack, preUser, preCardStack);
	else
		return self:shouldPassOppoAfter(curUser, curCardStack, preUser, preCardStack);
	end
end

function LogicHelp:shouldPassPartnerBefore(curUser, preUser, preCardStack)
    local preCardMap = preCardStack:getCardMap();
	if #preCardMap[16] > 0 or #preCardMap[17] > 0 then
		return true;
	end
	if preCardStack:getMinCardValue() >= 10 then
		return true;
	end
	if preCardStack:getCardCount() >= 6 then
		return true;
	end
	return false;
end

function LogicHelp:shouldPassOppoBefore(curUser, preUser, preCardStack)
	local preUserCardCount = preUser.cards:getCardCount();
	if preUserCardCount >= 10 then
		if preCardStack:getMinCardValue() > 14 then
			return true;
		end
        local preCardMap = preCardStack:getCardMap(); 
		if #preCardMap[16] or #preCardMap[17] > 0 then
			return true;
		end
	end
end

function LogicHelp:shouldPassPartnerAfter(curUser, curCardStack, preUser, preCardStack)
	local curCardMap = curCardStack:getCardMap();
    local preCardMap = preCardStack:getCardMap(); 
    for i=15,17 do
        if #curCardMap[i] > 0 then
            return true;
        end
    end

    local minValue = curCardStack:getMinCardValue();
	if #curCardMap[minValue] ~= curUser.cards:getCardCountByValue(minValue) then
		return true;
	end

    local preUserCardCount  = preUser.cards:getCardCount();
	if preUserCardCount < 10 and not self:getFollowPlayCardsForUser(preUser, curCardStack) then
		return true;
	end

    local maxValue = curCardStack:getMaxCardValue();
    if CardUtil.checkKaiDian(self.playCfg, curCardStack, minValue, maxValue) and (minValue - preCardStack:getMinCardValue() > 4) then
        return true;
    end
end

local function getCardCountInRange(cards, from, to)
    local count = 0;
    for i=from or 3,to or 17 do
        count = count + cards:getCardCountByValue(i);
    end
    return count;
end

function LogicHelp:shouldPassOppoAfter(curUser, curCardStack, preUser, preCardStack)
    local dianUser          = self.dianUser;
	local preUserCardCount 	= preUser.cards:getCardCount();

    if preUserCardCount == 1 then
    	return false;
    end

    local tmpCards = curUser.cards:clone();
    tmpCards:removeCards(curCardStack:getOrigCardList());
    local leftBigCardCount = getCardCountInRange(tmpCards,15,17);
    local leftCardDeckCount = 0;
    for i=4,15 do
        if tmpCards:getCardCountByValue(i) > 0 then
            leftCardDeckCount = leftCardDeckCount + 1;
        end
    end
    local usedBigCardCount = getCardCountInRange(curCardStack, 15,17);

    if preUserCardCount < 10 then
		return usedBigCardCount > 0 and leftBigCardCount < 3 and leftBigCardCount < leftCardDeckCount;    
    end

    local faceUser = self.userMgr:getFaceUserByUser(curUser);
    if (faceUser == preUser and faceUser == dianUser) or preUser.nRevoStat == g_GameConst.REVOSTAT.YES then
        return usedBigCardCount > 0 and leftBigCardCount < 3 and leftBigCardCount < leftCardDeckCount;           
    end

	if preUser == self.dianUser then
        return usedBigCardCount > 0;
    end

    -- 拆牌
    local minValue = curCardStack:getMinCardValue();
    local cardMap = curCardStack:getCardMap();
	if #cardMap[minValue] < self.cards:getCardCountByValue(minValue) then
		return true;
	end

    if CardUtil.checkGouJi(self.playCfg, curCardStack, minValue) and (minValue - preCardStack:getMinCardValue() > 4) then
        if self:canUserKaiDian(preUser) then
            return true;
        end
    end

    return usedBigCardCount > 0;
end

function LogicHelp:getFirstPlayCardsForUser(user)
    Log.v("LogicHelp:getFirstPlayCardsForUser", user.nUserId)
    local srcCardStack = user.cards;
    local srcCardMap = srcCardStack:getCardMap();
    if #srcCardMap[3] == srcCardStack:getCardCount() then
        return srcCardMap[3];
    end

    if user.nRevoStat == g_GameConst.REVOSTAT.YES then
        for k,v in pairs(self.playCfg.KDCARDS) do
            if #srcCardMap[k] >= v then
            	return srcCardMap[k];
            end 
        end
        return;
    end

    if self.dianUser == user then
    	if #srcCardMap[4] > 0 then
        	return srcCardMap[4];
        end
    end

    local isShao = user.nShaoStat == g_GameConst.SHAOSTAT.SUCC;
    local startPos = 4;
    if not self:canUserPlay4(user) or self:canUserKaiDian(user, true) then
    	startPos = 5;
    end
    for i=startPos,17 do
        if #srcCardMap[i] > 0 then
            local cards = srcCardMap[i];
            if i == 4 then
            	return cards;
            end
            local count = 0;
            for j=15,17 do
            	if j > i and self.playCfg.GUACARDS[j] then
            		count = count + #srcCardMap[j];
            	end
            end
            if count ~= 0 and count + #srcCardMap[i] == srcCardStack:getCardCount() - #srcCardMap[3] then
                cards = clone(cards);
                for j=15,17 do
                    if j > i and self.playCfg.GUACARDS[j] then
                        for _,card in ipairs(srcCardMap[j]) do
                            table.insert(cards, card);
                        end
                    end
                end
            end
            if isShao and cards[#cards].cardValue < 16 then
                for j=16,17 do
                    if #srcCardMap[j] > 0 then
                        cards = clone(cards);
                        table.insert(cards, srcCardMap[j][1]);
                        break;
                    end
                end
                if cards[#cards].cardValue < 16 then
                	return;
                end
            end

            return cards;
        end
    end
end

local _defaultTable =  {
    __index = function (t, k)
        local v = {};
        rawset(t, k, v);
        return v;
    end
}
function LogicHelp:getFollowPlayCardsForUser(user, preCardStack, card)
	Log.v("LogicHelp:getFollowPlayCardsForUser", user.nUserId, card)
	if card then
		local values = PlayHelp.getFollowPlayCardsByValue(card.cardValue);
		if not values or not table.indexof(values, card.cardValue) then
            return;
        end
        Log.v("LogicHelp:getFollowPlayCardsForUser, values", values)
        local cards = PlayHelp.selectCardsWithValues(srcCardStack, values)
        if cards then
            return cards;
        end
	else    
	    local srcCardStack = user.cards;
	    -- 先判断数量够不够压牌
	    if preCardStack:getCardCount() > srcCardStack:getCardCount() then
	        return false;
	    end

	    local preCardList = preCardStack:getOrigCardList();
	    table.sort(preCardList, function(a, b) return a.cardValue < b.cardValue; end);

	    local t = {};
	    setmetatable(t, _defaultTable);

	    local preCardCount = preCardStack:getCardCount();
	    local srcCardMap = srcCardStack:getCardMap();    
	    local startVal = preCardList[1].cardValue + 1;
	    if startVal == 4 and self:canUserKaiDian(user) then
	        startVal = 5;
	    end
	    if startVal > 17 then
	        startVal = 17;
	    end
	    for i=startVal,17 do
	        if #srcCardMap[i] > 0 then
	            if self.playCfg.GUACARDS[i] then
	                table.insert(t[preCardCount], i);
	            else
	                local diffCount = preCardCount - #srcCardMap[i];
	                if diffCount == 0 then
	                    table.insert(t[-1], i);
	                elseif diffCount < 0 then
	                    table.insert(t[0], i);
	                elseif diffCount > 0 then
	                    table.insert(t[diffCount], i); 
	                end
	            end            
	        end
	    end

	    local srcCardCount = srcCardStack:getPerValueCount();

	    for i=-1,preCardCount do
	        for _,value in ipairs(t[i]) do
	            local values = PlayHelp.getFollowPlayCardsByValue(self.playCfg, srcCardCount, preCardStack, value);
	            if values then
	                local cards = PlayHelp.selectCardsWithValues(srcCardStack, values)
	                if cards then
	                    local cardStack = CardStack.createInstanceFromCards(cards);
	                    if self:checkAIPlayCards(user, cardStack) then
	                    	return cards;
	                    end
	                end
	            end        
	        end
	    end

	end
end

function LogicHelp:getCanXuanUsers()
	local list = TableUtil.selectValues(self.userList, function (i,v)
		local faceUser = self.userMgr:getFaceUserByUser(v);
		return v.nRank == 0 and faceUser.nRank == 0;
	end);
	return list;
end

function LogicHelp:setAnitTributeForUser(user, atType, atCards, helpUser)
	if atType > self.antiTributes[user.nUserId].type then
		self.antiTributes[user.nUserId].uid = user.nUserId;
		self.antiTributes[user.nUserId].type = atType;
		self.antiTributes[user.nUserId].cards = atCards;
		if helpUser then 
			self.antiTributes[user.nUserId].helpId = helpUser.nUserId;
		end
	end
end

function LogicHelp:payTribute()
	Log.v("LogicHelp:payTribute")
	if not self.result then
		return;
	end
	local cfg = self.playCfg;
	local payTributes = self.payTributes;
	local rtnTributes = self.rtnTributes;
	local antiTributes = self.antiTributes;

	for i,v in ipairs(self.userList) do
		local atType, atCards = self:getAntiTributeByUser(v);
		self:setAnitTributeForUser(v, atType, atCards, v);
		if atType == g_GameConst.ATTYPE.UNION then
			for i=1,2 do
				local user = self.userMgr:getOffsetUserByUser(v, 2*i);
				self:setAnitTributeForUser(user, atType, atCards, v);
			end
		end 
	end

	local tributeMap = self.result.tributeMap;
	for _,tributeType in ipairs(cfg.TRIBUTE_SEQ) do
		for _,info in ipairs(tributeMap[tributeType]) do
			local fromUser = self.userMgr:getUserById(info.fromUid);
			if antiTributes[fromUser.nUserId].type == g_GameConst.ATTYPE.NONE then
				local toUser = self.userMgr:getUserById(info.toUid);
				local t = {};
				t.fromUid = info.fromUid;
				t.toUid = info.toUid;
				t.cards = {};
				t.type = tributeType;
				local cardMap = fromUser.cards:getCardMap();
				for i=1,info.num do
					local card = self:getTributeCardForUser(fromUser);
					if card then
						fromUser.cards:removeCard(card);
						local tribute = card:getTributeCard();
						toUser.cards:addCard(tribute);
						table.insert(t.cards, tribute.cardByte);
					else
						break;
					end
				end

				table.insert(payTributes, t);

				if cfg.RTN_CARD_FLAG[tributeType] and #t.cards > 0 then
					local t1 = {};
					t1.fromUid = t.toUid;
					t1.toUid = t.fromUid;
					t1.num = #t.cards;
					t1.type = tributeType;

					local t2 = rtnTributes[t1.fromUid];
					t2.num = t2.num + t1.num;					
					table.insert(t2.info, t1);
				end
			end
		end
	end
end

function LogicHelp:getMoneyCardForUser(user, val)
	local info = self.playCfg.BUY_CARD[val];
	if not info then return; end
	local cardMap = user.cards:getCardMap();
	for _,val in ipairs(info.cardOrder) do
		for _,card in ipairs(cardMap[val]) do
			if not card:isTributeCard() then
				return card;
			end
		end
	end
end

function LogicHelp:getTributeCardForUser(user)
	local cardMap = user.cards:getCardMap();
	for _,val in ipairs(self.playCfg.TRIBUTE_CARD) do
		for _,card in ipairs(cardMap[val]) do
			if not card:isTributeCard() then
				return card;
			end
		end
	end
end

function LogicHelp:getAntiTributeByUser(user)
	local cardMap = user.cards:getCardMap();
	local atType = g_GameConst.ATTYPE.NONE;
	local atCards;
	for _,info in ipairs(self.playCfg.ANTI_TRIBUTE) do
		if info.type > atType then
			local t = {};
			for _,v in ipairs(info.cards) do
				for _,v in ipairs(cardMap[v]) do
					table.insert(t, v.cardByte);
					if #t >= info.num then
						atType = info.type;
						atCards = t;
						break;
					end
				end
				if #t >= info.num then
					break;
				end
			end
			if atType == g_GameConst.ATTYPE.UNION then
				break;
			end
		end
	end

	return atType, atCards;
end

function LogicHelp:checkRtnTribute(user, bytes)
	Log.v("LogicHelp:checkRtnTribute", user.nUserId)
	local rtnCardInfo = self.rtnTributes[user.nUserId];
	if not rtnCardInfo then
		return false, g_CmdCode.RTN_TRIBUTE_ERR_INVALID_USER;
	end
	if not bytes or #bytes == 0 then
		return false, g_CmdCode.RTN_TRIBUTE_ERR_INVALID_CARDS;
	end
	local cards = CardUtil.convertBytesToCards(bytes);
	for i, v in ipairs( cards ) do
		if v.cardValue == 3 or v.cardValue == 4 then
			return false, g_CmdCode.RTN_TRIBUTE_ERR_INVALID_CARDS;
		end
		if v:isTributeCard() then
			return false, g_CmdCode.RTN_TRIBUTE_ERR_INVALID_CARDS;
		end
	end
	if #cards ~= rtnCardInfo.num then
		return false, g_CmdCode.RTN_TRIBUTE_ERR_INVALID_NUM;
	end
	if not user.cards:removeCards(cards) then
		return false, g_CmdCode.RTN_TRIBUTE_ERR_INVALID_CARDS;
	end
	local num = rtnCardInfo.num;
	for _,v in ipairs(rtnCardInfo.info) do
		local t1 = {};
		local t2 = {};
		for i=1,v.num do
			t1[#t1+1] = bytes[num-i+1];
			t2[#t2+1] = cards[num-i+1];
		end
		num = num - v.num;
		v.cards = t1;
		local user = self.userMgr:getUserById(v.toUid);
		user.cards:addCards(t2);
	end
	return true;
end

function LogicHelp:isGouJi(user, cardType)
	return not self.isLeft4 and self:isUserYouTou(user) and CardUtil.isContainByBit(cardType, g_GameConst.CARDTYPE.GOU_JI);
end

function LogicHelp:getNextPlayer(round)
	-- 首位出牌，烧牌或革命异常无人出牌
	local playRecord = round:getLastRecord(g_CmdCode.PLAY_OP_CALL);	
	if not playRecord then
		local player = round.players and round.players[1];
		if player then
			for i=1,5 do
				local user = self.userMgr:getOffsetUserByUser(player, i);
				if user.nRank == 0 then
					Log.v("LogicHelp:getNextPlayer, inherit user", user.nUserId)
					return user;
				end
			end
		end
		error("LogicHelp:getNextPlayer, no valid player");
	end

	local playUser = playRecord.user;
	local lastRecord = round:getLastRecord();
	local lastUser = lastRecord.user;
	Log.v("LogicHelp:getNextPlayer", lastUser.nUserId, playUser.nUserId, playRecord.cardStack:getOrigCardList(), playRecord.cardType)	
	
	local isGouJi = self:isGouJi(playUser, playRecord.cardType);
	local faceUser = self.userMgr:getFaceUserByUser(playRecord.user);

	-- 够级刷新对家状态
	if isGouJi and faceUser.nPlayStat == g_GameConst.PLAYSTAT.PASS then
		if lastUser == playUser or self.userMgr:isUserBetweenTwoUser(lastUser, playUser, faceUser) then
			local users = self.userMgr:getUsersBetweenTwoUser(lastUser, faceUser);
			for i,v in ipairs(users) do
				if not self:isUserYouTou(v) and self:canUserPlayCard(v) then
					break;
				end
				if i == #users then
					faceUser.nPlayStat = g_GameConst.PLAYSTAT.DEFAULT;
				end
			end
		end
	end

	-- 先判断有没玩家可以正常应牌
	for i=1,6 do
		local user = self.userMgr:getOffsetUserByUser(lastUser, i);
		repeat 
			if user == playUser then
				break;
			end
			if not self:canUserPlayCard(user) then
				break;
			end
			if isGouJi and user ~= faceUser and self:isUserYouTou(user) then
				break;
			end
			Log.v("LogicHelp:getNextPlayer, valid user", user.nUserId)
			return user;
		until true
	end

	-- 对门无过牌
	if not self.isLeft4 then
		local user = self.userMgr:getFaceUserByUser(playUser);
		if user ~= lastRecord.user and user.nRank == 0 and not user.isMen and checkint(round.askPlayTimes[user]) == 0 then
			return user;
		end
	end

	-- 无人可以接牌时由上次出牌玩家继续出牌
	if playUser.nRank == 0 then
		Log.v("LogicHelp:getNextPlayer, last user", playUser.nUserId)
		return playUser;
	end

	-- 接风
	for i=1,5 do
		local user = self.userMgr:getOffsetUserByUser(playUser, i);
		if user.nRank == 0 then
			Log.v("LogicHelp:getNextPlayer, inherit user", user.nUserId)
			return user;
		end
	end		

	error("no valid user, fatal error");
end

function LogicHelp:canUserShaoCards(user, preCardStack)
	if user.nRank ~= 0 then
		return false;
	end

	if not self:isUserYouTou(user) then
		return false;
	end

	if not self:canUserPlayCard(user) then
		return false;
	end

	if not preCardStack then
		return false;
	end

	return PlayHelp.canShaoCards(self.playCfg, user.cards, preCardStack)
end

function LogicHelp:getDianCardsFromCards(cards)
    local t = {};
    local cardMap = cards:getCardMap();
    for k,v in pairs(self.playCfg.KDCARDS) do
    	if #cardMap[k] >= v then
    		t[#t+1] = cardMap[k];
    	end
    end
    return t;
end

function LogicHelp:getXuanForUser(user)
	-- do return true end
	if not user.bRobot then
        return false;
    end
    local faceUser = self.userMgr:getFaceUserByUser(user);
    if faceUser.bRobot then
        return false;
    end
    
    if user.cards:getCardCountByValue(4) == 0  then
        return false;
    end

    local t = self:getDianCardsFromCards(user.cards);
    if #t == 0 then
    	return false;
    end

    if self:getPlayCardsToFollowCards(faceUser.cards:clone(), t) then
        return false;
    end

    if faceUser.cards:getCardCountByValue(4) == 0 then
        return math.random(1, 10) <= 3;
    end

    local t = self:getDianCardsFromCards(faceUser.cards);
    if table.nums(kdCards) > 0 and not self:getPlayCardsToFollowCards(user.cards:clone(), kdCards) then
        return false;
    end
    
    return math.random(1, 10) <= 3;
end

function LogicHelp:getRevoForUser(user)
    if not user.bRobot then
        return false;
    end
    return math.random(1, 10) <= 5;
end

function LogicHelp:getBuy4ForUser(user)
	-- do return true end;
    if not user.bRobot then
        return false;
    end
    local faceUser = self.userMgr:getFaceUserByUser(user);
    if faceUser.bRobot then
        return false;
    end
    local t = self:getDianCardsFromCards(user.cards);
    if #t == 0 then
        return false;
    end
	return not self:getPlayCardsToFollowCards(faceUser.cards:clone(), t);
end

function LogicHelp:getRtnTributeForUser(user, num)
	local t = {};
	local cardMap = user.cards:getCardMap();
	for i = 5,17 do
		for _,v in ipairs(cardMap[i]) do
			table.insert(t, v.cardByte);
			if #t == num then
				return t;
			end
		end
	end
	assert(false, "no card to return");
end

function LogicHelp:getShaoForUser(user, preUser, preCardStack)
	-- do return true end
	if not user.bRobot or preUser.bRobot then
		return false;
	end

	if self.userMgr:isPartner(user, preUser) then
		return false;
	end

	local _, cardStack = self:getFollowPlayCardsForUser(user, preCardStack);
	if not cardStack then
		return false;
	end

	if self:canUserShaoCards(preUser, cardStack) then
		return false;
	end

	for _,v in ipairs(self.userList) do
		if not v.bRobot and v ~= user and v ~= preUser and not self.userMgr:isPartner(v, user) then
			if self:canUserShaoCards(v, cardStack) then
				return false;
			end
		end
	end

	return true;
end

return LogicHelp;