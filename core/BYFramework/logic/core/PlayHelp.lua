local CardStack = import(".CardStack")
local TableUtil = import(".TableUtil")

local PlayHelp = {};

function PlayHelp.getFirstPlayCardsByValue(cfg, srcCardStack, value)
    local cards = srcCardStack:getCardsByValue(value)
    return cards;
end

function PlayHelp.getFollowPlayCardsByValue(cfg, srcCardCount, preCardStack, value)
    if not value then
        local minValue = preCardStack:getMinCardValue();
        for i=minValue + 1,17 do
            if srcCardCount[i] > 0 then
                value = i;
                break;
            end
        end
        if not value then 
            value = 17;
        end
    end

    local iterateCards = {value};
    if value > 4 then
        for i = 15,17 do
            if i > value and cfg.GUACARDS[i] then
                iterateCards[#iterateCards+1] = i;
            end
        end
    end

    local count = 0;
    for _,v in ipairs(iterateCards) do
        count = count + srcCardCount[v];
    end
    if count < preCardStack:getCardCount() then
        return;
    end

    local playCards = {};
    local preCardList = preCardStack:getOrigCardList();
    table.sort(preCardList, function(a, b) return a.cardValue < b.cardValue; end);
    local curIndex = #preCardList;

    local function add_to_play_cards(value, cardNum)
        cardNum = cardNum or 1;
        if srcCardCount[value] < cardNum then
            return false;  
        end
        srcCardCount[value] = srcCardCount[value] - cardNum;
        for i = 1, cardNum do
            table.insert(playCards, value);
        end
        return true;
    end

    local function remove_from_play_cards(cardNum)
        cardNum = cardNum or 1;
        for i = 1, cardNum do
            local value = table.remove(playCards, 1);
            srcCardCount[value] = srcCardCount[value] + 1;
        end
    end

    local function traverse_card()
        if curIndex <= 0 then
            coroutine.yield(playCards);
        end

        local curValue = preCardList[curIndex].cardValue;
        if curValue == 15 and cfg.GUACARDS[curValue] then  --当2作为挂牌时，2当癞子处理
            curValue = preCardList[1].cardValue;
        end

        if cfg.SPLCARDS[curValue] then
            for _,v in ipairs(cfg.SPLCARDS[curValue]) do
                if add_to_play_cards(v[1], v[2]) then
                    curIndex = curIndex - 1;
                    traverse_card();
                    curIndex = curIndex + 1;
                    remove_from_play_cards(v[2]);
                end
            end
            return;
        end

        for _, v in ipairs(iterateCards) do
            if v > curValue and srcCardCount[v] > 0 then
                local num = 1;
                while num < curIndex and num < srcCardCount[v] and preCardList[curIndex - num] == curValue do 
                    num = num + 1;
                end
                if add_to_play_cards(v, num) then
                    curIndex = curIndex - num;
                    traverse_card();
                    curIndex = curIndex + num;
                    remove_from_play_cards(num);
                end
            end
        end 
    end

    local co = coroutine.create(function() traverse_card() end)
    local code, result = coroutine.resume(co);
    if not code then
        error(debug.traceback(co, result));
        return;
    end

    co = nil;
    if result then
        local t = clone(result);
        remove_from_play_cards(#result);
        return t;
    end
end

function PlayHelp.selectCardsWithValues(cardStack, values)
    if not values or #values == 0 then
        Log.e("PlayHelp.selectCardsWithValues, no values")
        return 
    end
    local cardMap = cardStack:getCardMap();
    local countMap = {};
    for _,v in ipairs(values) do
        countMap[v] = (countMap[v] or 0) + 1;
    end
    local cards = {};
    for i=1,17 do
        if countMap[i] and countMap[i] > 0 then
            table.sort(cardMap[i]);
            for j=1,countMap[i] do
                table.insert(cards, cardMap[i][j]);
            end
        end
    end
    return cards;
end

function PlayHelp.canShaoCards(cfg, srcCardStack, preCardStack)
    local srcCardMap = srcCardStack:getCardMap();
    if #srcCardMap[4] > 0 then
        return false;
    end

    local srcCardCount = srcCardStack:getPerValueCount();
    local values = PlayHelp.getFollowPlayCardsByValue(cfg, srcCardCount, preCardStack);
    if not values or #values == 0 then
        return false;
    end

    local cards = PlayHelp.selectCardsWithValues(srcCardStack, values)
    local newCardStack = srcCardStack:clone();
    newCardStack:removeCards(cards);

    local newCardMap = newCardStack:getCardMap();
    if #newCardMap[3] == newCardStack:getCardCount() then
        return true;
    end

    local jkrNum = #newCardMap[16] + #newCardMap[17];
    if jkrNum == 0 then
        return false;
    end

    for i=5,cfg.GUACARDS[15] and 14 or 15 do
        if #newCardMap[i] > 0 then
            jkrNum = jkrNum - 1;
        end
    end
    
    return jkrNum >= 0;
end

function PlayHelp.compareCards(cfg, curCardStack, preCardStack)
    if not curCardStack or curCardStack:getCardCount() == 0 then
        return false;
    end

    if not preCardStack or preCardStack:getCardCount() == 0 then
        return true;
    end

    local srcCardCount = curCardStack:getPerValueCount();
    local values = PlayHelp.getFollowPlayCardsByValue(cfg, srcCardCount, preCardStack);
    if not values then
        return false;
    end
    local cards = PlayHelp.selectCardsWithValues(curCardStack, values);
    local newCardStack = CardStack.createInstanceFromCards(cards);
    local m1 = curCardStack:getCardMap();
    local m2 = newCardStack:getCardMap();

    for k,v in pairs(m1) do
        if #m2[k] ~= #v then
            return false;
        end
    end

    for k,v in pairs(m2) do
        if #m1[k] ~= #v then
            return false;
        end
    end

    return true;
end

return PlayHelp;