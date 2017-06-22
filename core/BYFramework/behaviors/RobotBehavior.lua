--[[
    机器人行为组件,普通机器人应该有一下行为
]]

local BehaviorBase = import(".BehaviorBase")
local RobotBehavior = class("RobotBehavior", BehaviorBase)

function RobotBehavior:ctor()
    RobotBehavior.super.ctor(self, "RobotBehavior", nil, 1)
end
local bit = require"bit"
bit.blshift = bit.lshift
bit.brshift = bit.rshift


local function getCardInfo(cardByte)
    local cardTypeValue = cardByte;
    local cardType = bit.brshift(cardTypeValue, 4);
    local cardNoTypeValue = bit.band(cardTypeValue, 0x0f);

    if cardNoTypeValue == 1 or cardNoTypeValue == 2 then
        cardNoTypeValue = cardNoTypeValue + 13;
    elseif cardNoTypeValue == 14 or cardNoTypeValue == 15 then -- 处理大小王
        cardNoTypeValue = cardNoTypeValue + 2;
    end

    local cardInfo = {};

    cardInfo.cardByte = cardTypeValue;
    cardInfo.cardType = cardType;
    cardInfo.cardValue = cardNoTypeValue;
    return cardInfo;
end

local function getAllCards()
    local cards = {}
    for i = 0, 3 do
        for j = 1, 13 do
            local x = bit.blshift(i, 4);
            local value = bit.bor(x, j);
            table.insert(cards, value);
        end
    end
    table.insert(cards, 0x4e); -- 大小王
    table.insert(cards, 0x4f);

    local cardInfos = {};

    for i, cardByte in ipairs(cards) do
        local temp = getCardInfo(cardByte);
        cardInfos[i] = temp;
    end

    return cardInfos;
end

function RobotBehavior:bind(object)
    ---洗牌
    local function shuffling(object,cardList)
        local cards = cardList or getAllCards();
        local len = #cards;
        local list = {};
        local index = 1;
        print(len)
        for i = 1, len do
            math.newrandomseed()
            index = math.random(#cards);
            print(index)
            list[i] = cards[index];
            table.remove(cards, index);
        end
        return list;
    end

    object:bindMethod(self, "shuffling", shuffling);

    self:reset(object);
end

function RobotBehavior:unbind(object)
    object:unbindMethod(self, "shuffling")
end

function RobotBehavior:reset(object)
    object.handCards_ = {};
end


return RobotBehavior;