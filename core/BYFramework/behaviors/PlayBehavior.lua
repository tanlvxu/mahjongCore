--[[
    玩牌组件行为
]]

local BehaviorBase = import(".BehaviorBase")
local PlayBehavior = class("PlayBehavior", BehaviorBase)


local join  = 0; --加入游戏
local ready = 1; --准备
local call  = 2; --叫抢地址
local start = 3; --开始游戏
local outcard = 4; --出牌
local pass = 5; -- 不出
local handler = 6; -- 正在操作牌
local AI = 7; -- 正在操作牌

function PlayBehavior:ctor()

    local depends = {
        "SendMsgBehavior",
    }
    PlayBehavior.super.ctor(self, "PlayBehavior", depends, 100)
end

local changeStatus = function(object,status)
    local oldStatus = object.playStatus_;
    object.playStatus_ = status;
    local str = string.format("player 状态从 %s 切换到 %s",oldStatus,status);
    print(str);
end
function PlayBehavior:bind(object)
    ---叫准备
    local function callReady(object)
        if object.playStatus_ == join then
            changeStatus(object,ready)
        end
    end
    object:bindMethod(self, "callReady", callReady);

    ---进入托管状态
    local function enterAI(object)
        changeStatus(object,AI)
    end

    object:bindMethod(self, "enterAI", enterAI);

    local function getPlayStatus(object)
        return object.playStatus_;
    end

    object:bindMethod(self, "getPlayStatus", getPlayStatus);

    self:reset(object);
end

function PlayBehavior:unbind(object)
    object.playStatus_ = nil;
    object:unbindMethod(self, "shuffling")
end

function PlayBehavior:reset(object)
    object.playStatus_ = join;
end


return PlayBehavior;