--[[
    发送消息的行为
]]

local BehaviorBase = import(".BehaviorBase")
local SendMsgBehavior = class("SendMsgBehavior", BehaviorBase)


function SendMsgBehavior:ctor()
    SendMsgBehavior.super.ctor(self, "SendMsgBehavior", nil, 101)
end

function SendMsgBehavior:bind(object)
    ---洗牌
    local function callReady(object)
        print("向server发送准备消息")
    end
    object:bindMethod(self, "callReady", callReady);

    local function enterAI(object)
        print("向server发送托管消息")
    end

    object:bindMethod(self, "enterAI", enterAI);
    
    self:reset(object);
end

function SendMsgBehavior:unbind(object)
    object:unbindMethod(self, "shuffling")
end

function SendMsgBehavior:reset(object)
end


return SendMsgBehavior;