--[[
	操作手牌的工具类
]]

local bit=require("bit")
local Group = import(".group")

local NROWS = 6
local NCOLS = 10

------辅助方法，即非对外暴露的方法，请用 __ 做前缀 start-------------
local function __copy_table(from,to)	
    local len = #from
	for i = 1,len do
		table.insert(to,from[i])
	end
end


local function __create_unique_sub_groups(cards, count)

    if #cards < count then
        return {}
    end

    if #cards == count then
        return {table.copyTab(cards)}
    end

    local all_groups = {}

    local key = {}

    for i = 1, #cards do
        if key[cards[i]] == nil then
            key[cards[i]] = true

            local remove_card = table.remove(cards, i)
            local groups = __create_unique_sub_groups(cards, count)

            for j = 1, #groups do
                table.insert(all_groups, groups[j])
            end

            table.insert(cards, i, remove_card)
        end
        
    end

    return all_groups
end

local function __filter_unique_sub_groups(groups)

    local unique_groups = {}

    local key = {}

    for i = 1, #groups do
        local str_key = ""
        for j = 1, #groups[i] do
            str_key = str_key .. "_" .. groups[i][j]
        end
        key[str_key] = groups[i]
    end

    for k,v in pairs(key) do 
        table.insert(unique_groups, v)
    end

    return unique_groups
end

------辅助方法 end  -------------

local function is_in_table(tb,card)
	local len = #tb
	for i=1,len do
		if tb[i] == card then
			return true
		end
	end
	return false
end

local function format_cardlist_to_str(list)
	local str = ""
	for i=1,#list do
		str = str .. string.format("0x%02x",list[i]) .. "|"
	end
	return str
end

if g_ProjectConfig and g_ProjectConfig.isLocalServer then
    local name = {
        [0x01] = "一万",[0x02] = "二万",[0x03] = "三万",[0x04] = "四万",[0x05] = "五万",[0x06] = "六万",[0x07] = "七万",[0x08] = "八万",[0x09] = "九万",
        [0x11] = "一筒",[0x12] = "二筒",[0x13] = "三筒",[0x14] = "四筒",[0x15] = "五筒",[0x16] = "六筒",[0x17] = "七筒",[0x18] = "八筒",[0x19] = "九筒",
        [0x21] = "一条",[0x22] = "二条",[0x23] = "三条",[0x24] = "四条",[0x25] = "五条",[0x26] = "六条",[0x27] = "七条",[0x28] = "八条",[0x29] = "九条",
        [0x31] = "东风",[0x32] = "南风",[0x33] = "西风",[0x34] = "北风",
        [0x41] = "红中",[0x42] = "发财",[0x43] = "白板",
        [0x51] =  "春",[0x52] = "夏",[0x53] = "秋",[0x54] =  "冬",[0x55] = "梅",[0x56] = "兰",[0x57] = "菊",[0x58] = "竹",
    }

    local function format_cardlist_to_str(list)

        local str = {}
        for i=1,#list do
            local t
            if name[list[i]] then
                t = name[list[i]];
            else
                t = string.format("0x%02x",list[i]);
            end
            
            table.insert(str,t);  
        end

        return table.concat(str,"|")
    end

end


local function format_settleModel_to_str(settleModel)
	local pStr = ""
	for i=1,#settleModel do
		local item = settleModel[i]
		local fanGroupMapStr = ""
		for k,v in pairs(item.fanGroupMap or {}) do
			fanGroupMapStr = fanGroupMapStr .. string.format("k:%d,fan:%d,bei:%d,",k,v.fan,v.bei)
		end

		local moneyStr = ""
		local moneyItemList = item.moneyItemList
		for k,v in pairs(moneyItemList) do
			local moneyItemStr = v.name .. ":" .. v.totalMoney;
			local p2pMoneyItemStr = " p2pMoney:"
			for j=1,4 do
				p2pMoneyItemStr = p2pMoneyItemStr .. string.format("%d:%d|",j,v.p2pMoney[j])
			end
			moneyItemStr = moneyItemStr .. p2pMoneyItemStr

			moneyStr = moneyStr .."[" .. moneyItemStr .. "]"
		end
		local str = ""
		for k,v in pairs(item) do
			if k ~= "fanGroupMap" and k ~= "moneyItemList" and type(v) ~= "table" then
				str = str .. "," .. string.format("%s=%d",k,v)
			end
		end
		str = string.format("%s,fanGroupMap=%s,moneyStr=%s",
												str,fanGroupMapStr,moneyStr)
		pStr = pStr .. "\n" .. "seatId:" .. i .. "=>" .. str
	end
	return pStr
end


local function table_remove_card(tb,card)
	for i = #tb,1,-1 do
		if tb[i] == card then
			table.remove(tb,i)
			return true
		end
	end
	return false
end

local function get_suits(card)
	return bit.rshift(card,4)
end

local function get_face(card)
	return bit.band(card,0x0F)
end

local function get_suits_face(card)
	return bit.rshift(card,4),bit.band(card,0x0F)
end

local function make_card(row,col)
	return row * 0x10 + col;
end

local function is_feng_card(card)
	return get_suits(card) == 3;
end

local function is_jian_card(card)
	return get_suits(card) == 4;
end

local function check_row_col(row, col)

    if row ==0 or row == 1 or row == 2 then
        if col < 1 or col >= NCOLS then
            return false
        end
    elseif row == 3 then
        if col < 1 or col > 4 then
            return false
        end
    elseif row == 4 then
        if col < 1 or col > 3 then
            return false
        end
    end

    return true
end

local function check_card(card)
	local row,col = get_suits_face(card)
    if row == 0 and col == 0 then       --0暂认为是合法的，比如吃碰杠操作之后，ActionData.m_outCardData.card 为0
        return true
    end
    return check_row_col(row, col)
end

--注意，要跟op_type_config顺序相反
local op_type_name = {
  "chi_type",
  "peng_gang_type",
  "chi_peng_ting_type",
  "hu_type",
  "out_hu_type",
}

local op_type_config = {
    {OPE_OUT_HU_QI_FENG,OPE_OUT_HU_SHI_FENG},
    {OPE_HU, OPE_ZI_MO, OPE_GANG_HU, OPE_HUA_HU, OPE_TANZI_HU,OPE_SHA_BAO},
    {OPE_RIGHT_CHI_TING,OPE_MIDDLE_CHI_TING,OPE_LEFT_CHI_TING,OPE_PENG_TING},
    {OPE_PENG, OPE_GANG, OPE_HUA_GANG, OPE_QIANG_PENG, OPE_QIANG_GANG,OPE_COUNT3_PENG_GANG},
    {OPE_RIGHT_CHI, OPE_MIDDLE_CHI, OPE_LEFT_CHI, OPE_XFG_3X,},
}

local function get_type(opcodeMap)
    if type(opcodeMap) == "number" then
        opcodeMap = { [opcodeMap] = 1 }
    end

    for i = 1, #op_type_config do
        for j = 1, #op_type_config[i] do
            local op_code = op_type_config[i][j]
            if opcodeMap[op_code] == 1 then
                return #op_type_config - i + 1
            end
        end
    end

    return 0
end

local function get_op_list_by_name(type_name)

    for i = 1, #op_type_name do
        if op_type_name[i] == type_name then
            return op_type_config[#op_type_name - i + 1]
        end
    end

    return {}
end

local function is_equal_with_type_and_name(op_type, type_name)
    return op_type_name[op_type] == type_name
end

local function is_equal_with_code_and_name(op_code, type_name)
    if op_code == nil then
        return false
    end

    local op_type = get_type(op_code)
    if op_type == 0 then
        return false
    end

    return is_equal_with_type_and_name(op_type, type_name)
end

--shun  [Group,...]
--ke    [Card,...]
--jiang [Card,...]
local function get_all_groups(mahjong,groups,shun,ke,jiang)
	local chiCardsTb = {mahjong.leftChiCards,mahjong.middleChiCards,mahjong.rightChiCards}

	for _,v in ipairs(groups) do
		if v:isShun() then
			table.insert(shun,v)
		elseif v:isKe() then
			table.insert(ke,v)
		elseif v:isJiang() then
			table.insert(jiang,v:first())  
		end
	end
	for i=1,3 do
		local chiCards = chiCardsTb[i]
		local n = math.floor(#chiCards/3)
		for i = 1,n do
			local idx = (i-1)*3
			local group = new(Group)
			group:addThree(chiCards[idx+1],chiCards[idx+2],chiCards[idx+3])
			table.insert(shun, group)
		end
	end
	__copy_table(mahjong.pengGroups,ke)
	__copy_table(mahjong.buGangGroups,ke)
	__copy_table(mahjong.pengGangGroups,ke)
	__copy_table(mahjong.anGangGroups,ke)

    __copy_table(mahjong.col1GangGroups,ke)
    __copy_table(mahjong.col9GangGroups,ke)
    __copy_table(mahjong.row3GangGroups,ke)
    __copy_table(mahjong.row4GangGroups,ke)
    __copy_table(mahjong.xxxGangGroups,ke)

end

local function get_handcard_groups(groups,shun,ke,jiang)
	for _,v in ipairs(groups) do
		if v:isShun() then
			table.insert(shun,v)
		elseif v:isKe() then
			table.insert(ke,v:first())
		elseif v:isJiang() then
			table.insert(jiang,v:first())
		end
	end
end

local function get_jiang(groups)
	local jiang
	for _,v in ipairs(groups) do
		if v:isJiang() then
			jiang = v
		end
	end
	if jiang then
		return jiang:first()
	end
	return nil
end

local function is_yao_jiu_card(card)
    local row, col = get_suits_face (card)
    if row == 5 then
        return false
    elseif row < 3 then
        return col == 1 or col == 9
    end
    return true
end

local function get_unique_sub_groups(cards, count, start)
    start = start or 1
    if #cards < count then
        return {}
    end

    if #cards == count then
        return {table.copyTab(cards)}
    end

    local all_groups = {}

    local key = {}

    for i = start, #cards do
        if key[cards[i]] == nil then
            key[cards[i]] = true

            local remove_card = table.remove(cards, i)
            local groups = get_unique_sub_groups(cards, count, i)

            for j = 1, #groups do
                table.insert(all_groups, groups[j])
            end

            table.insert(cards, i, remove_card)
        end
        
    end

    return all_groups
end

--将cards里面的元素，按照count一组的方式组合成group，返回{group,group}
--input cards={1,2,3}
--input count=2
--return {{1,2},{1,3},{2,3}}
local function get_all_sub_groups(cards, count, start)

    start = start or 1

    if #cards < count then
        return {}
    end

    if #cards == count then
        return {table.copyTab(cards)}
    end

    local all_groups = {}

    for i = start, #cards do

        local remove_card = table.remove(cards, i)
        local groups = get_all_sub_groups(cards, count, i)

        for j = 1, #groups do
            table.insert(all_groups, groups[j])
        end

        table.insert(cards, i, remove_card)
    end

    return all_groups
end

--在matrix查找cards里面的元素，
--input cards={1,2,3}
--input matrix = {{1,1,2,4}}
--return {1,1,2}
local function find_all_cards(matrix, cards)
    local all_cards = {}

    for i =1, #cards do

        local row,col = get_suits_face(cards[i])

        for j = 1, matrix[row][col] do
            table.insert(all_cards, cards[i])
        end
        
    end

    return all_cards;
end

--在matrix查找cards里面的元素，
--input cards={1,2,3}
--input matrix = {{1,1,2,4}}
--return {1,2}
local function find_all_types(matrix, cards)
    local all_types = {}

    for i =1, #cards do

        local row,col = get_suits_face(cards[i])
        if matrix[row][col] > 0 then
            table.insert(all_types, cards[i])
        end
    end

    return all_types;
end

--清空数组
local function clear_table(tt)

    if type(tt) ~= "table" then
        return false
    end

    for k,v in pairs(tt) do
        tt[k] = nil
    end

    return true
end

--在tt中查找card的数量
local function get_card_count(tt, card)

    if type(tt) == "number" then
        if tt == card then
            return 1
        end

        return 0
    end

    if type(tt) ~= "table" then
        return 0
    end

    local count = 0

    for i = 1, #tt do
        count = count + get_card_count(tt[i], card)
    end

    return count
end

local function get_laizi_count_in_group(group,laiziInfo)
    if #group == 0 then
        return 100 --返回一个极大值，表示优先级最低
    end
    local laiziCount = 0
    local lowLaiziCount = 0
    for i=1,#group do
        local c = group[i]
        if laiziInfo[c] then
           
            if #laiziInfo[c].beChange ~= 0 then
                lowLaiziCount = lowLaiziCount + 1
            else
                 laiziCount = laiziCount + 1
            end
        end
    end
    return laiziCount,lowLaiziCount
end

local function combine_card_toGroup(allGroups)
   local totalGroup = {}
   for k,v in ipairs(allGroups) do
       local tempCount = 0 ;
       local tempGroup = {} ;
       if not totalGroup[k] then totalGroup[k] = {} ; end
       for _,card in ipairs(v[1]) do
            tempCount = tempCount + 1;
            table.insert(tempGroup,card) ;
            if tempCount == v[2] then
            tempCount = 0 ;
            table.insert(totalGroup[k],tempGroup) ;
            tempGroup = {} ;
            end        
       end
   end
   return totalGroup ;
end

local M = {
	get_suits = get_suits,
	get_face = get_face,
	get_suits_face = get_suits_face,
	make_card = make_card,
	is_feng_card = is_feng_card,
	is_jian_card = is_jian_card,
	is_in_table = is_in_table,
	get_all_groups = get_all_groups,
	get_handcard_groups = get_handcard_groups,
	get_jiang = get_jiang,
    check_row_col = check_row_col,
	check_card = check_card,
	table_remove_card = table_remove_card,
	get_max_op = get_max_op,
	get_type= get_type,
    get_op_list_by_name=get_op_list_by_name,
    is_equal_with_type_and_name=is_equal_with_type_and_name,
    is_equal_with_code_and_name=is_equal_with_code_and_name,
    is_yao_jiu_card = is_yao_jiu_card,
    format_cardlist_to_str = format_cardlist_to_str,
    format_settleModel_to_str = format_settleModel_to_str,
    get_all_sub_groups = get_all_sub_groups,
    get_unique_sub_groups = get_unique_sub_groups,
    find_all_cards = find_all_cards,
    find_all_types = find_all_types,
    clear_table = clear_table,
    get_card_count = get_card_count,
    get_laizi_count_in_group = get_laizi_count_in_group,
    combine_card_toGroup = combine_card_toGroup,
}

return {M,NROWS,NCOLS}
