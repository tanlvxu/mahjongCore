---
-- Author: myc
-- Date: 2017-05-03 11:54:50
--
package.path = package.path .. ";../?.lua;"
require("functions")
require("dump");
require("bit")
-- dump(bit)
require("profiler")
bit.brshift = bit.rshift

local Card = import("..core.Card")
local TableUtil =  import("..core.TableUtil")

---打印牌数组
function printCards(cards)
	cards = checktable(cards);
	local ret = {};
	for k,v in pairs(cards) do
		table.insert(ret,tostring(v));
	end
	local result = "{" .. table.concat(ret, ",") .. "}";
	print(result)

	return result
end
---创建一副牌

-- local removeList = {0x11}

--[[ 
麻将牌编码如下表
============================================
0x01 0x02 0x03 0x04 0x05 0x06 0x07 0x08 0x09
一万 二万 三万 四万 五万 六万 七万 八万 九万
============================================
0x11 0x12 0x13 0x14 0x15 0x16 0x17 0x18 0x19
一筒 二筒 三筒 四筒 五筒 六筒 七筒 八筒 九筒
============================================
0x21 0x22 0x23 0x24 0x25 0x26 0x27 0x28 0x29
一条 二条 三条 四条 五条 六条 七条 八条 九条
============================================
0x31 0x32 0x33 0x34 
东风 南风 西风 北风 
============================================
0x41 0x42 0x43
红中 发财 白板 
============================================
0x51 0x52 0x53 0x54 0x55 0x56 0x57 0x58
春   夏   秋   冬   梅   兰   菊   竹   
============================================
*]]
-- function createCards()
-- 	local cards = {}
-- 	for i = 0, 2 do
-- 		for j = 1, 9 do
-- 			local x = bit.lshift(i, 4);
-- 			local value = bit.bor(x, j);
-- 			table.insert(cards, value);
-- 		end
-- 	end
-- 	-- table.insert(cards, 0x4e); -- 大小王
-- 	-- table.insert(cards, 0x4f);

-- 	local cardList = {};

-- 	for i, cardByte in ipairs(cards) do
-- 		local c = Card.new(cardByte)
-- 		table.insert(cardList,c);
-- 	end
-- 	return cardList;
-- end



---测试一手牌的内存
function testMemory()
	local memory_s = collectgarbage("count");
	local luaVMStr = string.format("发牌之前LUA内存: %0.2f KB", memory_s);
	print(luaVMStr);

	local cardList = createCards(); --测试洗牌

	local memory_e = collectgarbage("count");
	local luaVMStr = string.format("发牌之后LUA内存: %0.2f KB", memory_e);
	print(luaVMStr);

	local card_memory =  (memory_e - memory_s)/54
	local luaVMStr = string.format("单张牌LUA内存: %0.2f KB", card_memory);
	print(luaVMStr);
end


local function initMatrix()
	local mt = {}
	mt[1] = {[-1] = 0,[0] = 0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --万
	mt[2] = {[-1] = 0,[0] = 0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --筒
	mt[3] = {[-1] = 0,[0] = 0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --条
	mt[4] = {[-1] = 0,[0] = 0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --东南西北
	mt[5] = {[-1] = 0,[0] = 0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --红中 发财 白板 
	mt[6] = {[-1] = 0,[0] = 0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --春   夏   秋   冬   梅   兰   菊   竹
	
	return mt
end



local Mahjong = class();

function Mahjong:ctor()
	self.matrix = initMatrix()
	-- printMT(self.matrix)
end

function Mahjong:add(card)
	local row,col = card.cardType,card.cardValue;
	local mt = self.matrix;
	mt[row][col] = mt[row][col] + 1;
	mt[row][0] = mt[row][0] + 1;
end

function Mahjong:remove(cards)
	local mt = self.matrix;
	for i,card in pairs(cards) do
		local row,col = card.cardType,card.cardValue;
		if mt[row][col] == 0 then
			error("非法操作")
		else
			local tmp = table.remove(mt[row][col],1)
			mt[row][10] = mt[row][10] - 1;
			if #mt[row][col]== 0 then
				mt[row][col] = 0;
			end	
		end
	end
end

function Mahjong:printMT(mt)
	local mt = mt or self.matrix;
	for i,v in ipairs(mt) do
		local str = {};
		for i=-1,9,1 do
			local v2 = v[i]
			local t
			if type(v2) == "number" then
				t = string.format("[%d]=%d",i,v2)
			else
				local tmp =  {}
				for i,card in ipairs(v2) do
					table.insert(tmp,tostring(card));
				end
				tmp = table.concat(tmp,",")
				t = "{" .. tmp .."}";
				t = "[".. i .."]" .. "=" .. t;

			end	
			table.insert(str,t);
		end
		str = table.concat(str,",")
		local s = "{" .. str .. "}"
		print(s)
	end
end

function Mahjong:cloneMT(mt)
	local mt = mt or self.matrix;
	local t = {}
	for i,cards in ipairs(mt) do
		t[i] = {};
		for j=-1,9,1 do
			t[i][j] = cards[j];
		end
	end
	return t;
end

function Mahjong:getCard(row,col)
	local x = bit.lshift(row-1, 4);
	local value = bit.bor(x, col);
	local c = Card.new(value)
	return c;
end


function Mahjong:check_left_chi(card)
	local row,col = card.cardType,card.cardValue;
	local mt = self.matrix;

	if col>7 or row > 3 then --不是万通条，而且大于7 不满足左吃
		return;
	end
	local ret = {};
	if mt[row][col+1]~=0 and mt[row][col+2] ~= 0 then
		table.insert(ret,mt[row][col+1][1])
		table.insert(ret,mt[row][col+2][1])
		return ret;
	end

	return;

end

function Mahjong:check_right_chi(card)
	local row,col = card.cardType,card.cardValue;
	local mt = self.matrix;

	if (col < 2 or col> 9) or row > 3 then 
		return;
	end
	local ret = {};
	if mt[row][col-1]~=0 and mt[row][col-2] ~= 0 then
		table.insert(ret,mt[row][col-1][1])
		table.insert(ret,mt[row][col-2][1])
		return ret;
	end

	return;
end

function Mahjong:check_middle_chi(card)
	local row,col = card.cardType,card.cardValue;
	local mt = self.matrix;

	if (col < 1 or col> 8) or row > 3 then 
		return;
	end
	local ret = {};
	if mt[row][col-1]~=0 and mt[row][col+1] ~= 0 then
		table.insert(ret,mt[row][col-1][1])
		table.insert(ret,mt[row][col+1][1])
		return ret;
	end
	return;
end

function mayHu(mt)
	if remainPai(mt) then
		return true;
	end
	for row,col in ipairs(mt) do
		for i,v in ipairs(col) do
			if v == 4 then
				col[i] = 0;
				col[0] = col[0] - 4
				if mayHu(mt) then
					return true;
				end
				col[i] = 4;
				col[0] = col[0] + 4
			end
			if v >= 3 then
				col[i] = col[i] - 3;
				col[0] = col[0] - 3
				if mayHu(mt) then
					return true;
				end
				col[i] = col[i] + 3;
				col[0] = col[0] + 3
			end

			if v >=2 then
				col[i] = col[i] - 2;
				col[-1] = col[-1] + 1;
				col[0] = col[0] - 2
				if mayHu(mt) then
					return true;
				end
				col[i] = col[i] + 2;
				col[-1] = col[-1] - 1;
				col[0] = col[0] + 2
			end
			if row <= 3 and v> 0 and i <=7 and col[i + 1] > 0 and col[i + 2] > 0 then --万通条
				col[i] = col[i] - 1;
				col[i+1] = col[i+1] - 1;
				col[i+2] = col[i+2] - 1;
				col[0] = col[0] - 3
				if mayHu(mt) then
					return true;
				end
				col[i] = col[i] + 1;
				col[i+1] = col[i+1] + 1;
				col[i+2] = col[i+2] + 1;
				col[0]  = col[0] + 3
			end
		end
	end
	return false;
end

-- function mayHu(mt)
-- 	if remainPai(mt) then
-- 		return true;
-- 	end
-- 	for row,col in ipairs(mt) do
-- 		for i=-1,9,0 do
-- 			if col[i] > 0 then
-- 				col[i] = 0;
-- 				mayHu(mt)
-- 			end
-- 		end
-- 	end
-- 	return false
-- end

function remainPai(mt)
	local sum = 0;
	local dui = 0
	for row,col in ipairs(mt) do
		-- for i,v in ipairs(col) do
			sum = sum + col[0]
			if dui < col[-1] then
				dui = col[-1]
			end
		-- end
	end
	if sum == 0 then
		if dui <= 2 then
			return true;
		elseif dui == 7 then
			return true;
		else
			return false;
		end
		return true;
	end
	return false;
end


function ting(mj)
		
	local mt = mj.matrix
	if mayHu(mt) == true then
		print("hu")
		return;
	end

	for row,cards in ipairs(mt) do
		for i,v in ipairs(cards) do
			if v > 0 then
				local orgMT = mj:cloneMT();
				orgMT[row][i] = orgMT[row][i] - 1;
				for k=1,9 do
					orgMT[row][k] = orgMT[row][k] + 1;
					if mayHu(orgMT) then
						local outCard 	= mj:getCard(row,i)
						local card 		= mj:getCard(row,k)						
						local str = string.format("打掉%s,胡%s",tostring(outCard),tostring(card))
						print(str)
						orgMT = mj:cloneMT()
						orgMT[row][i] = orgMT[row][i] - 1;
					else
						orgMT[row][k] = orgMT[row][k] - 1;
					end
				end
			end
		end

	end
end


function createCards()
	local cards = {0x05,0x05, 0x05,0x04,0x04, 0x04, 0x07,0x08,0x06,0x12,0x13}
	-- local cards = {0x04,0x04, 0x04, 0x04,0x08,0x06}
	local cardList = {};

	for i, cardByte in ipairs(cards) do
		local c = Card.new(cardByte)
		table.insert(cardList,c);
	end
	return cardList;
end

local function main( ... )
	-- profiler = newProfiler("call")
	--    profiler:start()
	local cardList = createCards();
	printCards(cardList)
	local mj = new(Mahjong)
	for i,v in ipairs(cardList) do
		mj:add(v)
	end
	
	profiler = newProfiler("call")
 	profiler:start()
	
	ting(mj)


    local outfile = io.open( "profile.txt", "w+" )
    profiler:report( outfile )
    outfile:close()

	mj:printMT()


end


main()
