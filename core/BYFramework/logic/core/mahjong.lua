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
--import(".object")
local utils,NROWS,NCOLS = unpack(import(".utils"))

local Mahjong = class("Mahjong",GameObject)

local function initMatrix()
	local mt = {}
	mt[0] = {[-1] = 0,[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --万
	mt[1] = {[-1] = 0,[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --筒
	mt[2] = {[-1] = 0,[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --条
	mt[3] = {[-1] = 0,[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --东南西北
	mt[4] = {[-1] = 0,[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --红中 发财 白板 
	mt[5] = {[-1] = 0,[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0,[6]=0,[7]=0,[8]=0,[9]=0} --春   夏   秋   冬   梅   兰   菊   竹
	return mt
end

local function cloneMatrix(srcMt)
	local mt = {}
	for i=0,NROWS-1 do
		mt[i] = {}
		for j=-1,NCOLS-1 do
			mt[i][j] = srcMt[i][j]
		end
	end
	return mt
end

function Mahjong:ctor()
	self:clearMatrix()
	self.leftChiCards = {}
	self.middleChiCards = {}
	self.rightChiCards = {}
	self.pengCards = {}
	self.buGangCards = {}
	self.pengGangCards = {}
	self.anGangCards = {}
  	self.xfg3xCards = {}
  	self.xfg4xCards = {}

  	self.count3pengGangCards = {} --三张牌成碰杠
  	self.count3anGangCards = {}   --三张牌成暗杠
  	self.count1GangCards = {}     --一张牌成杠，常见于花牌或者红中

    self.flowerCards = {}

	self.groups = {}
	self.outedCards = {} --{{card,status:0正常 or 1已被人吃碰杠走,2是弃牌}}
	self.laizi = {} --记录癞子牌

    --特殊杠group
    self.col1GangGroups = {}
    self.col9GangGroups = {}
    self.row3GangGroups = {}
    self.row4GangGroups = {}
    self.xxxGangGroups = {}

    self.count3pengGangGroups = {} --三张牌成碰杠的完整组合
  	self.count3anGangGroups = {}   --三张牌成暗杠的完整组合

	self.pengGroups = {}     --已碰牌
	self.buGangGroups = {}
	self.pengGangGroups = {}
	self.anGangGroups = {}   --已暗杠

end



function Mahjong:clearMatrix()
	self.matrix = initMatrix()
	self.lz_matrix = initMatrix()
end

function Mahjong:getMergeMatrix()
	local mt = initMatrix()
	for i=0,NROWS-1 do
		for j=-1,NCOLS-1 do
			mt[i][j] = self.matrix[i][j] + self.lz_matrix[i][j]
		end
	end
	return mt
end

function Mahjong:clear()
  	self:clearMatrix()
  	self.leftChiCards = {}
	self.middleChiCards = {}
	self.rightChiCards = {}
	self.pengCards = {}
	self.buGangCards = {}
	self.pengGangCards = {}
	self.anGangCards = {}
    self.xfg3xCards = {}
    self.xfg4xCards = {}

    self.count3pengGangCards = {} --三张牌成碰杠
  	self.count3anGangCards = {}   --三张牌成暗杠
  	self.count1GangCards = {}     --一张牌成杠，常见于花牌或者红中

    self.flowerCards = {}

	self.outedCards = {} --{{card,status:0正常 or 1已被人吃碰杠走,2是弃牌}}
	self.groups = {}
	self.laizi = {} --记录癞子牌

    self.col1GangGroups = {}
    self.col9GangGroups = {}
    self.row3GangGroups = {}
    self.row4GangGroups = {}
    self.xxxGangGroups = {}

	self.pengGroups = {}     --已碰牌的所有牌,可能有癞子
	self.anGangGroups = {}   --已暗杠的所有牌,可能有癞子
	self.buGangGroups = {}
	self.pengGangGroups = {}

	self.count3pengGangGroups = {} --三张牌成碰杠的完整组合
  	self.count3anGangGroups = {}   --三张牌成暗杠的完整组合

end


--isNative 是否指定为原生牌，默认为false
function Mahjong:add(card,num,isNative)
	num = num or 1
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	--是癞子牌且没有指定为原生，存到lz_matrix，否则存到matrix
	local mt
	if isNative ~= true and self:isLaizi(card) == true then
		mt = self.lz_matrix
	else
		mt = self.matrix
	end

	mt[row][col] = mt[row][col] + num
	mt[row][0] = mt[row][0] + num
  	mt[row][-1] = mt[row][-1] + num
  return true
end

--设置已出牌的状态，1为被人吃碰杠走,2弃牌
--只能设置最后一张出的牌
function Mahjong:setOutedCardStatus(card,status)
	local len = #self.outedCards
  if len <= 0 or self.outedCards[len].card ~= card then
    return
  end
  self.outedCards[len].status = status
end

--出牌列表加入弃牌 server change
function Mahjong:addFoldCardToOutedCards(card)
	table.insert(self.outedCards,{card=card,status=2})
	return true
end

--isNative 是否指定为原生牌，默认为false
function Mahjong:remove(card,isOutedCard,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end

	--是癞子牌且没有指定为原生，从lz_matrix移除，否则从matrix移除
	local mt
	if isNative ~= true and self:isLaizi(card) == true then
		mt = self.lz_matrix
	else
		mt = self.matrix
	end

	if mt[row][col] < 1 then
		return false
	end
	if isOutedCard == true or isOutedCard == nil then
		table.insert(self.outedCards,{card=card,status=0})
	end
	mt[row][col] = mt[row][col] - 1;
	mt[row][0] = mt[row][0] - 1;
 	mt[row][-1] = mt[row][-1] - 1;
	return true
end

--添加到花牌列表,
--card,牌值
--isHandCard,该牌是否在手牌里面
function Mahjong:addFlowerCard(card, isHandCard)

    local row,col = utils.get_suits_face(card)
	if row ~= 5 or col >= NCOLS then
		return false
	end

    table.insert(self.flowerCards, card)

    if isHandCard then
        self.matrix[row][col] = self.matrix[row][col] - 1
        self.matrix[row][0] = self.matrix[row][0] - 1
        self.matrix[row][-1] = self.matrix[row][-1] - 1
    end

    return true
end

--isNative 是否指定为原生牌，默认为true
function Mahjong:left_chi(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 2) and (1 <= col and col <= 7) then 
		if group and #group == 3 then
			local checkResult = self:check_group_card_count_legal(card,group)
			if checkResult == false then
				return false
			end

			isNative = isNative or (isNative == nil)
			local mt
			if isNative == false and self:isLaizi(card) == true then
				mt = self.lz_matrix
			else
				mt = self.matrix
			end
			mt[row][-1] = mt[row][-1] + 1 --吃了一个card回来，索引[-1]需要+1
			for kk=1,3 do
				table.insert(self.leftChiCards,group[kk])
			end
			return true,group
		end
	end
	return false;
end

function Mahjong:middle_chi(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 2) and (2 <= col and col <= 8) then
		if group and #group == 3 then
			local checkResult = self:check_group_card_count_legal(card,group)
			if checkResult == false then
				return false
			end

			isNative = isNative or (isNative == nil)
			local mt
			if isNative == false and self:isLaizi(card) == true then
				mt = self.lz_matrix
			else
				mt = self.matrix
			end
			mt[row][-1] = mt[row][-1] + 1 --吃了一个card回来，索引[-1]需要+1
			for kk=1,3 do
				table.insert(self.middleChiCards,group[kk])
			end
			return true,group
		end
	end
	return false;
end

function Mahjong:right_chi(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 2) and (3 <= col and col <= 9) then
		if group and #group == 3 then
			local checkResult = self:check_group_card_count_legal(card,group)
			if checkResult == false then
				return false
			end

			isNative = isNative or (isNative == nil)
			local mt
			if isNative == false and self:isLaizi(card) == true then
				mt = self.lz_matrix
			else
				mt = self.matrix
			end
			mt[row][-1] = mt[row][-1] + 1 --吃了一个card回来，索引[-1]需要+1
			for kk=1,3 do
				table.insert(self.rightChiCards,group[kk])
			end
			return true,group
		end
	end
	return false
end

--检查传进来的group里的牌是不是够减
--isSelfCard,是否玩家自己的抓牌后的操作检查
function Mahjong:check_group_card_count_legal(card,group,isSelfCard)
	local groupCountArr = {}
	for i=1,#group do
		local tmpCard = group[i]
		local tmpRow,tmpCol = utils.get_suits_face(tmpCard)
		if tmpRow >= NROWS or tmpCol >= NCOLS then
			return false
		end
		if not groupCountArr[tmpCard] then
			groupCountArr[tmpCard] = 0
		end
		groupCountArr[tmpCard] = groupCountArr[tmpCard] + 1
	end

	if not isSelfCard and groupCountArr[card] == nil then
		return false --group里的牌跟card毫不相干
	end

	if not isSelfCard then
		groupCountArr[card] = groupCountArr[card] - 1 --card为别人的牌，group里有张不是自己的牌
	end

	for c,count in pairs(groupCountArr) do
		local row,col = utils.get_suits_face(c)
		local mt
		if self:isLaizi(c) == true then
			mt = self.lz_matrix
		else
			mt = self.matrix
		end
		if mt[row][col] < count then --手牌不够减
			return false
		end
	end

	for c,count in pairs(groupCountArr) do
		local mt
		if self:isLaizi(c) == true then
			mt = self.lz_matrix
		else
			mt = self.matrix
		end
		local tmprow,tmpcol = utils.get_suits_face(c)
		mt[tmprow][tmpcol] = mt[tmprow][tmpcol] - count
		mt[tmprow][0] = mt[tmprow][0] - count
	end

	return true
end

--
function Mahjong:peng(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 4) and (1 <= col and col <= 9) then
		if group and #group == 3 then
			local checkResult = self:check_group_card_count_legal(card,group)
			if checkResult == false then
				return false
			end

			isNative = isNative or (isNative == nil)
			local mt
			if isNative == false and self:isLaizi(card) == true then
				mt = self.lz_matrix
			else
				mt = self.matrix
			end
			mt[row][-1] = mt[row][-1] + 1 --碰了一个card回来，索引[-1]需要+1
			table.insert(self.pengCards,card)
			for kk=1,3 do
				table.insert(self.pengGroups,group[kk])
			end
			return true,group
		end
	end
	return false
end



--[[--
通过比较两个group,来检测出调了多少牌
--@param g1 调之前的group
--@param g2 调之后的group
--@return mark 获得标记表
]]
local function compareGroup(g1,g2)
	local mark={};
    for k,v in pairs(g1) do
        mark[v] = mark[v] and mark[v]+1 or 1 ;
    end
    for k,v in pairs(g2) do
        if mark[v] then
           mark[v] = mark[v] - 1 ;
        else
           mark[v] = mark[v] and mark[v]-1 or -1 ;     
        end
    end
    return mark ;
end

--[[--
调牌操作 主要用于完成操作后的换牌
]]
function Mahjong:diao(card,group,isNative)
	if card == nil then 
      for k,v in pairs(group) do
          if not self:isLaizi(v) then
              card = v ;
              break ;
          end
      end
	end
	if not card then return false end;
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	local tempList = {self.pengCards,self.pengGangCards ,self.anGangCards ,self.buGangCards}
    local tempList1 = {
    {self.pengGroups,3},
    {self.pengGangGroups,4},
    {self.anGangGroups,4},
    {self.buGangGroups,4},
    }
    local tempList2 = utils.combine_card_toGroup(tempList1);
	if (0 <= row and row <= 4) and (1 <= col and col <= 9) then
	  --根据card来搜索属于什么类型的
	  local diaoType ;  
	  for i=1,#tempList do
		for k,v in pairs(tempList[i]) do 
            if v == card then
               diaoType = i ;
               break ;
            end
		end
		if diaoType then
			break ;
		end
	  end 
	  if not diaoType then return false end;
	  --取得要换的group
	  local cardGroupIndex ;
      for i=1,#tempList2[diaoType] do 
          local searchGroup = tempList2[diaoType][i] ;
          for k,v in pairs(searchGroup) do
             if v ~= card and not self:isLaizi(v)  then
                break ;
             elseif v == card then
                 cardGroupIndex = i;
                break ;
             end
          end
          if cardGroupIndex then
          	break ;
          end
       end
       if not cardGroupIndex then return false end;
       --交换group
       local desGroup = tempList2[diaoType][cardGroupIndex];
       tempList2[diaoType][cardGroupIndex] = group ;
       --改变手牌
       local mark = compareGroup(desGroup,group) ;
       for k,v in pairs(mark) do
           if v and v~=0 then
              for i=1,math.abs(v) do
                  if self:isLaizi(k) then
                     self:add(k);
                  else
                  	 self:remove(k,false);
                  end
              end
           end
       end
       --取得原来的group
       local originCardGroups =  tempList1[diaoType][1] ; 
       --之前的长度
       local originLen = tempList1[diaoType][2]*(cardGroupIndex - 1) ;
       for i =1 , tempList1[diaoType][2] do    
           originCardGroups[originLen + i] = group[i]
       end
       --插入新值返回
       local newGroup = {}
       for k,v in ipairs(desGroup) do
           table.insert(newGroup,v);
       end
       for k,v in ipairs(group) do
           table.insert(newGroup,v);
       end
       return true,newGroup ;
	end
	return false
end


function Mahjong:peng_gang(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 4) and (1 <= col and col <= 9) then
		if group and #group == 4 then
			local checkResult = self:check_group_card_count_legal(card,group)
			if checkResult == false then
				return false
			end

			isNative = isNative or (isNative == nil)
			local mt
			if isNative == false and self:isLaizi(card) == true then
				mt = self.lz_matrix
			else
				mt = self.matrix
			end
			mt[row][-1] = mt[row][-1] + 1 --碰了一个card回来，索引[-1]需要+1
			table.insert(self.pengGangCards,card)
			for kk=1,4 do
				table.insert(self.pengGangGroups,group[kk])
			end
			return true,group
		end
	end
	return false
end

function Mahjong:undo_peng_gang(card)
    local row, col = utils.get_suits_face(card)
    local mt = self.matrix

    mt[row][-1] = mt[row][-1] - 1
    mt[row][col] = mt[row][col] + 3
	mt[row][0]   = mt[row][0] + 3

    table.remove(self.pengGangCards)

    for kk=1,4 do
		table.remove(self.pengGangGroups)
	end
end

function Mahjong:undo_an_gang(card)
    local row, col = utils.get_suits_face(card)
    local mt = self.matrix

    mt[row][col] = mt[row][col] + 4
	mt[row][0]   = mt[row][0] + 4

    table.remove(self.anGangCards)

    for kk=1,4 do
		table.remove(self.anGangGroups)
	end
end

function Mahjong:an_gang(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 4) and (1 <= col and col <= 9) then
		if group and #group == 4 then
			local checkResult = self:check_group_card_count_legal(card,group,true)
			if checkResult == false then
				return false
			end

			table.insert(self.anGangCards,card)
			for kk=1,4 do
				table.insert(self.anGangGroups,group[kk])
			end
			return true,group
		end
	end
	return false
end

function Mahjong:__to_xxxGang(gangCards)
    table.copyTo(gangCards, self.xxxGangGroups[1])
    table.remove(self.xxxGangGroups, 1)
end

--回退为特殊杠的检测
function Mahjong:__restore_xxxGang(gangCards)
    
    if #self.xxxGangGroups == 0 then
        return false
    end

    local xxxGangCards = self.xxxGangGroups[1]

    if #gangCards > 4 or #xxxGangCards > 0 then
        return false
    end


    for i = 1, #gangCards do
        if gangCards[i] ~= 0x21 then
            return false
        end
    end

    table.copyTo(xxxGangCards, gangCards)

    utils.clear_table(gangCards)

    return true
end

function Mahjong:__undo_bu_xxxGang(card, gangCards)

    if #gangCards < 4 then
        return false
    end

    if gangCards[#gangCards] ~= card then
        return false
    end

    gangCards[#gangCards] = nil

    return true
end

function Mahjong:undo_bu_col1Gang(card)

    if #self.col1GangGroups == 0 then
        return false
    end

    local gangCards = self.col1GangGroups[1]

    if self:__undo_bu_xxxGang(card, gangCards) == false then
        return false
    end

    if self:__restore_xxxGang(gangCards) then
        return true, self.xxxGangGroups[1]
    end

    return true, gangCards
end

function Mahjong:undo_bu_col9Gang(card)

    if #self.col9GangGroups == 0 then
        return false
    end

    local gangCards = self.col9GangGroups[1]

    if self:__undo_bu_xxxGang(card, gangCards) == false then
        return false
    end

    if self:__restore_xxxGang(gangCards) then
        return true, self.xxxGangGroups[1]
    end

    return true, gangCards
end

function Mahjong:undo_bu_row3Gang(card)

    if #self.row3GangGroups == 0 then
        return false
    end

    local gangCards = self.row3GangGroups[1]

    if self:__undo_bu_xxxGang(card, gangCards) == false then
        return false
    end

    if self:__restore_xxxGang(gangCards) then
        return true, self.xxxGangGroups[1]
    end

    return true, gangCards
end


function Mahjong:undo_bu_row4Gang(card)

    if #self.row4GangGroups == 0 then
        return false
    end

    local gangCards = self.row4GangGroups[1]

    if self:__undo_bu_xxxGang(card, gangCards) == false then
        return false
    end

    if self:__restore_xxxGang(gangCards) then
        return true, self.xxxGangGroups[1]
    end

    return true, gangCards
end


function Mahjong:undo_bu_xxxGang(card)

    if #self.xxxGangGroups == 0 then
        return false
    end

    if self:__undo_bu_xxxGang(card, self.xxxGangGroups[1]) == false then
        return false
    end

    return true, self.xxxGangGroups[1]
end

function Mahjong:__insertXGang(card, group, gangCards)
    local checkResult = self:check_group_card_count_legal(card,group, true)
    if checkResult == false then
        return false
    end

    for i = 1, #group do
        local card = group[i]
        local row,col = utils.get_suits_face(card)
	    if row >= NROWS or col >= NCOLS then
		    return false
	    end

        table.insert(gangCards,card)
    end

    return true, gangCards
end

function Mahjong:__handleXGang(card, group, gangGroups)

    if #group == 1 then
        
        if #gangGroups == 0 and #self.xxxGangGroups == 0 then
            return false
        end

        if #gangGroups == 0 and #self.xxxGangGroups > 0 then
            table.insert(gangGroups, {})
            self:__to_xxxGang(gangGroups[1])
        end

        return self:__insertXGang(card, group, gangGroups[1])

    elseif #group >= 3 then
        table.insert(gangGroups, {})
        return self:__insertXGang(card, group, gangGroups[#gangGroups])
    end

    return false
end

function Mahjong:col1Gang(card, group)
    return self:__handleXGang(card, group, self.col1GangGroups)
end

function Mahjong:col9Gang(card, group)
    return self:__handleXGang(card, group, self.col9GangGroups)
end

function Mahjong:row3Gang(card, group)
    return self:__handleXGang(card, group, self.row3GangGroups)
end

function Mahjong:row4Gang(card, group)
    return self:__handleXGang(card, group, self.row4GangGroups)
end

function Mahjong:xxxGang(card, group)
    return self:__handleXGang(card, group, self.xxxGangGroups)
end 

function Mahjong:xfg3x(card, group, isSelfCard)
    
    local checkResult = self:check_group_card_count_legal(card,group, isSelfCard)
    if checkResult == false then
        return false
    end

    --do
    for i = 1, #group do
        local card = group[i]
        local row,col = utils.get_suits_face(card)
	    if row >= NROWS or col >= NCOLS then
		    return false
	    end

        table.insert(self.xfg3xCards,card)
    end

	return true
end

function Mahjong:xfg4x(card, group, isSelfCard)

    local checkResult = self:check_group_card_count_legal(card,group, isSelfCard)
    if checkResult == false then
        return false
    end

    --do
    for i = 1, #group do
        local card = group[i]
        local row,col = utils.get_suits_face(card)
	    if row >= NROWS or col >= NCOLS then
		    return false
	    end

        table.insert(self.xfg4xCards,card)
    end

	return true
end

function Mahjong:count3pengGang(card,group)
	local checkResult = self:check_group_card_count_legal(card,group)
    if checkResult == false then
        return false
    end
    table.insert(self.count3pengGangCards,card)
    for i=1,#group do
    	local tmpCard = group[i]
    	table.insert(self.count3pengGangGroups,tmpCard)
    end
    return true
end

function Mahjong:count3anGang(card,group)
	local checkResult = self:check_group_card_count_legal(card,group,true)
    if checkResult == false then
        return false
    end
    table.insert(self.count3anGangCards,card)
    for i=1,#group do
    	local tmpCard = group[i]
    	table.insert(self.count3anGangGroups,tmpCard)
    end
    return true
end

function Mahjong:count1Gang(card,group)
	local row,col = utils.get_suits_face(card)
    if row >= NROWS or col >= NCOLS then
	    return false
    end
    if self.matrix[row][col] <= 0 then
    	return false
    end
    self.matrix[row][col] = self.matrix[row][col] - 1
    self.matrix[row][0] = self.matrix[row][0] - 1
    table.insert(self.count1GangCards,card)
    return true
end


local function is_same_group(g1,g2)
	-- table.sort(g1)
	-- table.sort(g2)
	if #g1 ~= #g2 then
		return false
	end
	for i=1,#g1 do
		if g1[i] ~= g2[i] then
			return false
		end
	end
	return true
end

local function delete_group_in_list(list,group)
	local count = #group
	for i=#list,1,-count do
		local tg = {}
		for j=count-1,0,-1 do
			table.insert(tg,list[i-j])
		end
		if is_same_group(tg,group) then
			for j=0,count-1 do
				table.remove(list,i-j)
			end
			return true
		end
	end
	return false
end

--被抢杠后，把杠还原成碰
function Mahjong:undo_bu_gang(card)
  if utils.table_remove_card(self.buGangCards,card) then
    table.insert(self.pengCards,card);
    local row,col = utils.get_suits_face(card)
    if self:isLaizi(card) then
    	self.lz_matrix[row][-1] = self.lz_matrix[row][-1] - 1; 
    else
    	self.matrix[row][-1] = self.matrix[row][-1] - 1; 
    end
    
    local len = #self.buGangGroups
    for i=1,4 do
    	local index = len-i+1
    	if i > 1 then
    		table.insert(self.pengGroups,1,self.buGangGroups[index])
    		table.insert(self.pengCards,1,card) ;
    	end
    	table.remove(self.buGangGroups,index)
    end
  end
end

function Mahjong:bu_gang(card,group,isNative)
	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return false
	end
	if (0 <= row and row <= 4) and (1 <= col and col <= 9) then
		if group and #group == 4 then
			local tmpCard = group[4] --党中央规定，group中的最后一个是拿去补的牌
			local mt
			if self:isLaizi(tmpCard) == true then
				mt = self.lz_matrix
			else
				mt = self.matrix
			end
			local tmpRow,tmpCol = utils.get_suits_face(tmpCard)
			if mt[tmpRow][tmpCol] <= 0 then
				return false
			end

			local tmp_peng_group = {}
			for kk=1,3 do
				table.insert(tmp_peng_group,group[kk])
			end
			if delete_group_in_list(self.pengGroups,tmp_peng_group) then
				mt[tmpRow][tmpCol] = mt[tmpRow][tmpCol] - 1
				mt[tmpRow][0] = mt[tmpRow][0] - 1
				for kk=1,4 do
					table.insert(self.buGangGroups,group[kk])
				end
				for kk=1,#self.pengCards do
                    if self.pengCards[kk] == card then
                       table.remove(self.pengCards,kk);
                    end
				end
				table.insert(self.buGangCards,group[1])
				return true,group
			end
		end
	end
	return false
end

--获取从右边开始第一个牌(可以使用filters来过滤，即从右边开始获取第一张不在filters中的牌)
--@param filters table 需要过滤的牌， 可以为空
--@return card
function Mahjong:last(filters)

	local cardMap = {}
	for _,card in ipairs(filters or {}) do
		cardMap[card] = card
	end

    --优先找非癞子的牌
	for i = 4,0,-1 do
		for j = 9,1,-1 do
			if self.matrix[i][j] > 0 then
				local card = utils.make_card(i,j)
				if not cardMap[card] then
					return card
				end
			end
		end
	end
    
    for i = 4,0,-1 do
		for j = 9,1,-1 do
			if self.lz_matrix[i][j] > 0 then
				local card = utils.make_card(i,j)
				if not cardMap[card] then
					return card
				end
			end
		end
	end

	return 0
end

--isNative 是否指定为原生牌，默认为false
function Mahjong:countCard(card, isNative)

    local count = 0

	local row,col = utils.get_suits_face(card)
	if row >= NROWS or col >= NCOLS then
		return 0
	end
	count = self.matrix[row][col]

    if not isNative then
        count = count + self.lz_matrix[row][col]
    end

    return count
end

--计数除了花牌之外的牌--TODO 减去廊起的牌
function Mahjong:countHandCards()
	local num = 0
	for i = 0,4 do
		num = num + self.matrix[i][0] + self.lz_matrix[i][0]
	end
	return num
end

function Mahjong:countChiCards()
	return #self.leftChiCards + #self.middleChiCards + #self.rightChiCards
end

function Mahjong:getChiCards()
	local cards = table.merge2(self.leftChiCards, self.middleChiCards);
    table.merge(cards, self.rightChiCards)
    return cards
end


function Mahjong:countPengCards()
	return #self.pengCards 
end

---@function [parent=#Mahjong] countGangCards
-- @return #number 当前杠的总数 明杠+暗杠
function Mahjong:countGangCards()
	return  (#self.buGangGroups + #self.pengGangGroups + #self.anGangGroups)/4
end

--获取xGang的牌数量
function Mahjong:countXGang(gangGroups)
    local count = 0
    for i = 1, #gangGroups do
        count = count + #gangGroups[i]
    end
    return count
end

--计算除了花牌之外的牌张（含吃碰杠手）
function Mahjong:countTotalCards()
	local hand = self:countHandCards()
	local total = hand + self:countChiCards() + #self.pengCards*3 + self:countGangCards()*4
	total = total + #self.count3anGangGroups + #self.count3pengGangGroups + #self.count1GangCards
    total = total + #self.xfg3xCards + #self.xfg4xCards
    total = total + self:countXGang(self.col1GangGroups) + self:countXGang(self.col9GangGroups) + self:countXGang(self.row3GangGroups) + self:countXGang(self.row4GangGroups) + self:countXGang(self.xxxGangGroups)
	return total
end

--获取手牌中癞子牌的数目
--@return number 癞子牌的数目
function Mahjong:getLaiziCount()
	local count = 0
	for i=0,4 do
		count = count + self.lz_matrix[i][0]
	end
	return count
end

--获取可用的癞子列表
function Mahjong:getLaiziList()
	local tb = {}
	local diffLaizi = {}
	for card,info in pairs(self.laizi) do
		local row,col = utils.get_suits_face(card)
		local count = self.lz_matrix[row][col]
		if count > 0 then
			for i=1,count do
				table.insert(tb,card)
			end
			diffLaizi[card] = count
		end
	end
	return tb,diffLaizi
end

--设置癞子 {[card]={beChange={},count=*},}
--可以设置多个癞子
function Mahjong:setLaizi( laiziInfo )
	--先把原来的癞子信息还原
	for card,info in pairs(self.laizi) do
		local row,col = utils.get_suits_face(card)
		local count = self.lz_matrix[row][col]
		self.lz_matrix[row][col] = 0
		self.lz_matrix[row][0] = 0
		self.lz_matrix[row][-1] = 0
		if count > 0 then
			self.matrix[row][col] = self.matrix[row][col] + count
			self.matrix[row][0] = self.matrix[row][0] + count
			self.matrix[row][-1] = self.matrix[row][-1] + count
		end
	end

  	self.laizi = laiziInfo

  	for card,info in pairs(laiziInfo) do
  		local row,col = utils.get_suits_face(card)
		local ownCount = self.matrix[row][col]
		local lzCount = info.count or 4
		local count = math.min(lzCount,ownCount)
		if count > 0 then
			self.matrix[row][col] = self.matrix[row][col] - count
			self.matrix[row][0] = self.matrix[row][0] - count
			self.matrix[row][-1] = self.matrix[row][-1] - count

			self.lz_matrix[row][col] = self.lz_matrix[row][col] + count
			self.lz_matrix[row][0] = self.lz_matrix[row][0] + count
			self.lz_matrix[row][-1] = self.lz_matrix[row][-1] + count
		end
  	end

end
--设置临时癞子信息
function Mahjong:setTempLaizi(tempLaiziInfo)
	if self.m_origin_laiziInfo then
		self:restoreLaizi()
	end
	self.m_origin_laiziInfo = self.laizi

    self.m_origin_matrix = self.matrix
	self.m_origin_lz_matrix = self.lz_matrix

	self.matrix = cloneMatrix(self.m_origin_matrix)
	self.lz_matrix = cloneMatrix(self.m_origin_lz_matrix)

	self:setLaizi(tempLaiziInfo)
end
--恢复癞子信息
function Mahjong:restoreLaizi()
	if self.m_origin_laiziInfo then
		self.matrix = self.m_origin_matrix
		self.lz_matrix = self.m_origin_lz_matrix
		self.laizi = self.m_origin_laiziInfo

		self.m_origin_laiziInfo = nil
		self.m_origin_matrix = nil
		self.m_origin_lz_matrix = nil
	end
end

--是否是癞子
--@param card 卡牌
--@return bool
function Mahjong:isLaizi( card )
	return self.laizi[card] ~= nil
end


function Mahjong:getAllCardTable()
	local tb = {}
	for i = 0,4 do
		for j = 1,9 do
			if (self.matrix[i][j] + self.lz_matrix[i][j]) > 0 then
				local card = utils.make_card(i,j)
		        local num = self.matrix[i][j] + self.lz_matrix[i][j];
		        for i=1,num do
		          table.insert(tb,card)
		        end
			end
		end
	end
	return tb
end

function Mahjong:getAllCardTypeTable()
	local tb = {}
	for i = 0,4 do
		for j = 1,9 do
			if (self.matrix[i][j] + self.lz_matrix[i][j]) > 0 then
				local card = utils.make_card(i,j)
        		table.insert(tb,card)
			end
		end
	end
	return tb
end


function Mahjong:getAllCardAndCountStr()
	local tb = {}
  local cardStr = "";
  local counStr = "";
	for i = 0,4 do
		for j = 1,9 do
			if (self.matrix[i][j] + self.lz_matrix[i][j]) > 0 then
				local card = utils.make_card(i,j)
        cardStr = cardStr .. string.format("0x%02x:%d|",card,self.matrix[i][j] + self.lz_matrix[i][j]);
			end
		end
	end
  return cardStr;
end


function Mahjong:getAllCardString()
	local str = ""
	for i = 0,4 do
		for j = 1,9 do
			if (self.matrix[i][j] + self.lz_matrix[i][j]) > 0 then
				for k=1,(self.matrix[i][j] + self.lz_matrix[i][j]) do
					str = str .. string.format("0x%02x |",utils.make_card(i,j))
				end
			end
		end
		str = str .. "\n"
	end
	return str
end

function Mahjong:makeOutedCardMatrix()
	local matrix = initMatrix()
	for i=1,#self.outedCards do
		local row,col = utils.get_suits_face(self.outedCards[i].card)
		matrix[row][-1] = matrix[row][-1] + 1
		matrix[row][0] = matrix[row][0] + 1
		matrix[row][col] = matrix[row][col] + 1
	end
	return matrix
end

return Mahjong
