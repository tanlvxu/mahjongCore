package.path =   "../../../?.lua;" ..package.path  
package.path =   "../?.lua;" ..package.path  

local path = "";
local gameroot = "quickX.games.GouJi."
cjson = require("json");
g_Platform = kLocalServer;
g_LogLevel = 0
g_CommonPath	= "quickX.games.Gouji.common."
g_GamePath   	= "quickX.games.GouJi."
Log = require("Log");

require(path .. "quickX.framework._load");
require(path .. "quickX.engine._load");
g_GameConst = require(g_GamePath..".GameConst");
g_DGameConst = g_GameConst;
g_CmdCode = require(g_GamePath..".CmdCode")

local PlayHelp = require(path .. "logic.core.PlayHelp")
local CardStack = require(path .. "logic.core.CardStack")
local Card = require(path .. "logic.core.Card")
local TableUtil = require(path .. "logic.core.TableUtil")
local CardUtil = require(path .. "logic.core.CardUtil")
local PlayConfig = require(path .. "config.PlayConfig")
local _logicHelp = new( require(path .. "logic.LogicHelp") )
local GameResult = require(path .. "GameResult")
local GameUser = require(path .. "GameUser")
local _gameUsers = new(require(path .. "GameUsers"))
local _gameTable = new(require(path .. "TGameTable"))
local iGame = {};
iGame.m_pGameTable = _gameTable;
iGame.getGameUser = function ()
	return _gameUsers;
end
_gameUsers:initData(iGame)
for i,v in ipairs(_gameUsers:getAllUser()) do
	v.nUserId = 100 + i;
end
_gameTable.iGame = iGame;
_gameTable:InitSoInfo({iServerId = 1, iServerLevel = 12, iTabMaxUserCount = 6, nTableId = 1})
print(_gameTable.m_localConf)
local _tableData = new(require(path .. "GameData"), _gameTable)

function printCard( bytes )
	local cards = CardUtil.convertBytesToCards(bytes);	
	table.sort(cards)
	print(TableUtil.tostring(cards))
end
-- printCard();

function testCard( ... )
	local card = Card.new(79);
	print(TableUtil.tostring(card:getTributeCard()))
	print(TableUtil.tostring(card:getOriginalCard()))
end

function testRank( ... )
	local ranks = {1,2,5}
	local i,v = TableUtil.selectValue(playConfig.RANKTYPE, function (i,v)
		return TableUtil.isEqual(v.pattern, ranks);
	end, false)
	print(TableUtil.tostring(v))
end

function testPlayCard()
	local srcCards = {0x0f,0x0f, 0x10, 0x10, 0x10, 0x09,0x09,0x09}
	print(TableUtil.tostring(CardUtil.convertBytesToCards(srcCards)))
	local preCards = {0x02,0x02,0x09,0x09,0x09}
	print(TableUtil.tostring(CardUtil.convertBytesToCards(preCards)))
	local srcCardStack = CardStack.createInstanceFromBytes(srcCards);
	local t = PlayHelp.getFollowPlayCardsByValue(PlayConfig, srcCardStack:getPerValueCount(), CardStack.createInstanceFromBytes(preCards))
	print(TableUtil.tostring(t or {}))
end
testPlayCard();

function testShao( ... )
	local srcCards = {0x4F,0x31}
	print(TableUtil.tostring(CardUtil.convertBytesToCards(srcCards)))
	local preCards = {0x3D,0x0D}
	print(TableUtil.tostring(CardUtil.convertBytesToCards(preCards)))
	local t = PlayHelp.canShaoCards(PlayConfig, CardStack.createInstanceFromBytes(srcCards), CardStack.createInstanceFromBytes(preCards));
	print(t)
end
-- testShao()

function testCardType( ... )
	local srcCards = {15,34,2,49,49,33,17,61,45}
	print(TableUtil.tostring(CardUtil.convertBytesToCards(srcCards)))
	-- local preCards = {79}
	-- print(TableUtil.tostring(CardUtil.convertBytesToCards(preCards)))
	local t = CardUtil.getCardType(PlayConfig, CardStack.createInstanceFromBytes(srcCards))
	print(t)
end
-- testCardType()

function testPlayCardFirst()
	local user = new(GameUser)
	local srcCards = {0x33, 0x21, 0x02, 0x02, 0x4E, 0x4F}
	print(TableUtil.tostring(CardUtil.convertBytesToCards(srcCards)))
	user.cards = CardStack.createInstanceFromBytes(srcCards);
	local t = _logicHelp:getFirstPlayCardsForUser(user);
end
-- testPlayCardFirst()

function setUserRank(user, rank)
	user.nRank = rank;
	_tableData.rankList[rank] = user;
end

function testGameResult()
	_gameTable.m_localConf.nBaseChips = 1000
	_tableData.nFactor = 2;
	_tableData.userList[1].nMoney = 6800 - 3400
	_tableData.userList[2].nMoney = 9306 + 19783
	_tableData.userList[3].nMoney = 185473 - 27997
	_tableData.userList[4].nMoney = 0 + 6953
	_tableData.userList[5].nMoney = 36328 - 18164
	_tableData.userList[6].nMoney = 20178 + 22825

	setUserRank(_tableData.userList[1], 1)
	setUserRank(_tableData.userList[2], 4)
	setUserRank(_tableData.userList[3], 2)

	setUserRank(_tableData.userList[4], 5)
	setUserRank(_tableData.userList[5], 3)
	setUserRank(_tableData.userList[6], 6)

	_tableData.userList[1].nDianStat = g_GameConst.DIANSTAT.SUCC;
	_tableData.userList[1].nXuanStat = g_GameConst.XUANSTAT.OPEN;
	_tableData.userList[4].nDianStat = g_GameConst.DIANSTAT.FAIL;
	_tableData.userList[4].nXuanStat = g_GameConst.XUANSTAT.OPEN;

	table.insert(_tableData.shaoList, {fromUid = 102, toUid = 103, count = 1});

	local result = GameResult.getResult(_tableData);

	for i,v in ipairs(_tableData.userList) do
		Log.v("testGameResult, score, i", i, result.scoreMap[v.nUserId].m_score, result.scoreMap[v.nUserId].m_finalScore)
	end
	for i=1,2 do
		local users = _gameUsers:getTeamUsersById(i);
		table.sort(users, function (a,b) return a.nRank < b.nRank; end)
		for i,v in ipairs(users) do
			local score = result.scoreMap[v.nUserId].m_score;
			local _, finalScore = result:getTotalScore(v);
			print(i, v.nRank, score[1],score[2],score[3],score[4],score[5], 
				finalScore, v.nMoney, result.moneyMap[v.nUserId].winMoney, result.moneyMap[v.nUserId].finalWinMoney);			
		end
	end
end
-- testGameResult();

function testCardPower()
	local bytes = {3,4,4,17,17,17,17,19,20,20,33,33,33,33,34,35,35,36,36,49,49,51,51,52,52,78,78,78,78,79,79,79,79};
	printCard(bytes)
	local cardStack = CardStack.createInstanceFromBytes(bytes);
	print(CardUtil.getCardStackPower(PlayConfig, cardStack))
end
-- testCardPower();

function testJson( ... )
	local json = [[
		{"avatar_m":"","exp":100,"userId":100098924,"m_identity":0,"city":"山东 济南","gold":216540,"level":10,"cid":100063883,"winCount":0,"diamond":0,"avatar_s":"","money":216540,"loseCount":0,"avatar_b":"","drawCount":0,"appid":903000,"sex":0,"nickName":"L50t","crystal":0}
	]]

	local status, userInfo = pcall(function() return cjson.decode(json) end);
	print(status, TableUtil.tostring(userInfo))
end
-- testJson();

function testMemory()
	local luaVMStr = string.format("之前LUA内存: %0.2f MB", collectgarbage("count") / 1024);
	print(luaVMStr);
	local t = {};
	-- for i=1, 1000 do
		for j=1, 198*2 do
			-- local card = Card.new(0x01);
			-- table.insert(t, card);
			-- table.insert(t, CardStack.createInstanceFromCards({card}))
			-- table.insert(t, 0x01)
			testPlayCard();
		end
	-- end
	local luaVMStr = string.format("之后LUA内存: %0.2f MB", collectgarbage("count") / 1024);
	print(luaVMStr);
	collectgarbage("collect")
	local luaVMStr = string.format("GC之后LUA内存: %0.2f MB", collectgarbage("count") / 1024);
	print(luaVMStr);
end
testMemory();