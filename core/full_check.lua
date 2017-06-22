
require("BYFramework._load");
local utils,NROWS,NCOLS = unpack(import("utils"))
local Group = import("group")
local function setGroupIndex(i,j,k,flag,mark,groupIdxs,index)
	mark[i] = flag
	mark[j] = flag
	mark[k] = flag

	groupIdxs[i] = index
	groupIdxs[j] = index
	groupIdxs[k] = index
end

local function getNextSeqIdx(handcards,cardCount,index,card,mark)
	if card > 0x30 then
		return -1
	end
	for i=index,cardCount do
		if mark[i] ~= true then
			if handcards[i] == card+1 then
				return i
			elseif handcards[i] > card+1 then
				return -1
			end
		end
	end
	return -1
end

local function getSameSeqIdx(handcards,cardCount,index,card,mark)
	for i=index,cardCount do
		if mark[i] ~= true then
			if handcards[i] == card then
				return i
			elseif handcards[i] ~= card+1 then
				return -1
			end
		end
	end
	return -1
end

local function getUnuseCards(handcards,cardCount,mark)
    local unUseCards = {}

	for i=1,cardCount do
		if mark[i] ~= true then
			table.insert(unUseCards,handcards[i])
		end
	end

    return unUseCards
end

local function __simple_check2(params)

    local couns = {}

    for card,count in pairs(params.card_count_map) do

        local row, col = utils.get_suits_face(card)
        couns[row] = couns[row] or 0

        couns[row] = couns[row] + count

    end

    local needLaiziCount = 0

    for k,count in pairs(couns) do

        if count % 3 ~= 0 then
            needLaiziCount = needLaiziCount + 3 - (count % 3)
        end

    end

    if needLaiziCount > params.laiziCount then
        return false
    end

    return true
end


local function __remove(data, params)
    local group = {}

    if type(data) == "table" then
        group = data
    elseif type(data) == "number" then
        group = {data}
    end

    for i = 1, #group do

        local card = group[i]
        if card == -1 then
            params.laiziCount = params.laiziCount - 1
        else
            params.card_count_map[card] = params.card_count_map[card] - 1
        end
    end
end

local function __add(data, params)

    local group = {}

    if type(data) == "table" then
        group = data
    elseif type(data) == "number" then
        group = {data}
    end

    for i = 1, #group do

        local card = group[i]
        if card == -1 then
            params.laiziCount = params.laiziCount + 1
        else
            params.card_count_map[card] = params.card_count_map[card] + 1
        end
    end
end

local function __get_unuse_cards(card_count_map)

    local unUseCards = {}

    for card, count in pairs(card_count_map) do

        for i = 1, count do
            table.insert(unUseCards, card)
        end

    end
    table.sort(unUseCards)
    return unUseCards
end

function get_incomplete_full_comb2(params)

    local laiziCount = params.laiziCount
    local completeMap = params.completeMap
    local card_count_map = params.card_count_map


    if #completeMap.jiang == 0 then

        local jiang_comb_groups = {}

        for card,count in pairs(card_count_map) do
            if count >= 2 then
                table.insert(jiang_comb_groups, {card, card})
            elseif count == 1 and params.laiziCount > 0 then
                table.insert(jiang_comb_groups, {card, -1})
            end
        end


        if laiziCount > 1 then
            table.insert(jiang_comb_groups, {-1, -1})
        end

        for i = 1, #jiang_comb_groups do
            
            __remove(jiang_comb_groups[i], params)

            if __simple_check2(params) == false then
                __add(jiang_comb_groups[i], params)
            else
                table.insert(completeMap.jiang, jiang_comb_groups[i])

                get_incomplete_full_comb2(params)

                __add(jiang_comb_groups[i], params)

                table.remove(completeMap.jiang)
            end
            
        end
        
        return 
    end

    do
        if params.laiziCount >= 3 then
            for i = 1, params.laiziCount, 3 do
                local group = {-1, -1, -1}

                __remove(group, params)
                table.insert(params.completeMap.ke, group)

                get_incomplete_full_comb2(params)

                __add(group, params)
                table.remove(params.completeMap.ke)
            end
        end
        

        for card,count in pairs(card_count_map) do
            if count > 0 and count + params.laiziCount >= 3 then

                local group = nil
                if count == 2 then
                    group = {card, card, -1}
                elseif count == 1 then
                    group = {card, -1, -1}
                elseif count >=3 then
                    group = {card, card, card}
                end

                __remove(group, params)
                table.insert(params.completeMap.ke, group)

                get_incomplete_full_comb2(params)

                __add(group, params)
                table.remove(params.completeMap.ke)

            end

        end

    end

    do
        laiziCount = params.laiziCount

        local unUseCards = __get_unuse_cards(card_count_map)
        local shun = {}
        local i = 1
        local shun_groups = {}
        local unUseCardJian = {} ;
        local unUseWTT = {} ;
        for k,v in pairs(unUseCards) do
            if v > 0x30 then
             table.insert(unUseCardJian,v);
            else
             table.insert(unUseWTT,v);
            end
        end
        if #unUseCardJian > 0 then
            return false ;
        end
       -- Log.v("TerryTan unUseCardJian",unUseCardJian);
        -- Log.v("TerryTan unUseWTT",unUseWTT);
        --此处是非箭牌三刻组
        if #unUseWTT >0 then
        while true do
            if #shun == 0 then
            	--(unUseCards[i] > 0x30 and  region_condition.getFengJianThreeComb ) or 
            	--if unUseWTT[i] <0x30 then
                       table.insert(shun, unUseWTT[i])
            	--end       
                i = i + 1
            else
                if unUseWTT[i] == shun[#shun] + 1 then
                    table.insert(shun, unUseWTT[i])
                    i = i + 1
                elseif shun[#shun] == -1 and unUseWTT[i] == shun[1] + 2 then
                    table.insert(shun, unUseWTT[i])
                    i = i + 1
                else
                    if laiziCount == 0 then
                        return
                    end

                    if #shun == 2 and shun[2] == -1 then
                        return
                    end

                    table.insert(shun, -1)
                    laiziCount = laiziCount - 1

                end
                
                if #shun == 3 then
                    table.insert(shun_groups, shun)
                    shun = {}
                end

            end

            if i > #unUseWTT then
                break
            end
        end
        end
        if laiziCount > 1 then
            return 
        elseif laiziCount == 1 then
            table.insert(shun, -1) 
        end
        
        if #shun == 3 then
            table.insert(shun_groups, shun)
        end

        local newCompleteMap = table.copyTab(params.completeMap)
        newCompleteMap.shun = shun_groups
        table.insert(params.completeMaps, newCompleteMap)
    end

end

local function __simple_check(unUseCards, laiziCount)

    local couns = {}

    for i = 1, #unUseCards do

        local row, col = utils.get_suits_face(unUseCards[i])
        couns[row] = couns[row] or 0

        couns[row] = couns[row] + 1

    end

    local needLaiziCount = 0

    for k,count in pairs(couns) do

        if count % 3 ~= 0 then
            needLaiziCount = needLaiziCount + 3 - (count % 3)
        end

    end

    if needLaiziCount > laiziCount + 1 then
        return false
    end

    return true
end

local function get_incomplete_full_comb(unUseCards,laiziCount)

    if __simple_check(unUseCards, laiziCount) == false then
        return false
    end

    local card_count_map = {}

    for i = 1, #unUseCards do
        local card = unUseCards[i]
        if card_count_map[card] == nil then
            card_count_map[card] = 0
        end
        card_count_map[card] = card_count_map[card] + 1
        --g_REGION_CONFIG.lua_laizi_incomplete_check_level ~= 3 and
     --   if  card_count_map[card] >= 3 then
     --       return false
     --   end
    end

    local params = {}
    params.laiziCount = laiziCount
    params.card_count_map = card_count_map
    params.completeMap = {shun = {}, ke = {}, jiang = {}}
    params.completeMaps = {}

	get_incomplete_full_comb2(params)

    return #params.completeMaps > 0, params.completeMaps
end

local function get_incomplete_full_comb_wenshan(unUseCards,mahjong)

    local diffLaizi = {[0x21] = 2 };

    local changeLaizi = {}

	local laiziInfo =  {[0x21]={beChange={},count=4},[0x43]={beChange={0x21, 0x43},count=4}}
	for card,count in pairs(diffLaizi) do
		local beChange = laiziInfo[card].beChange or {}
		if #beChange > 0 then
            for i = 1, count do
                table.insert(changeLaizi, {card=card, beChange=beChange})
            end
        end
	end

    local params = {}

    params.laiziCount = 2;
    params.changeLaizi = changeLaizi
    params.unUseCards = table.copyTab(unUseCards)
    params.checkLevel = 1   --有组合则返回
    params.completeMaps = {}
    params.changeIndexs= {}
    params.changeIndex = {}

    local __branch_check = nil

    __branch_check = function(params, start)
        
        local changeLaizi = params.changeLaizi

        for i = start, #changeLaizi do
            
            local beChange = changeLaizi[i].beChange

            for j = 1, #beChange do

                table.insert(params.unUseCards, beChange[j])
                table.insert(params.changeIndex, {changeLaizi[i].card, beChange[j]})

                if __branch_check(params, i + 1) == true and  params.checkLevel == 1 then
                    table.remove(params.unUseCards)
                    table.remove(params.changeIndex)
                    return true
                end
                
                table.remove(params.unUseCards)
                table.remove(params.changeIndex)
            end

        end

        if start > #changeLaizi then
            
            local laiziCount = params.laiziCount - #changeLaizi

            local ret, completeMaps = get_incomplete_full_comb(params.unUseCards, laiziCount)
            if ret == true then
                table.insert(params.completeMaps, completeMaps)
                table.insert(params.changeIndexs, table.copyTab(params.changeIndex))
                return ret
            end
        end

        return false
    end

    __branch_check(params, 1)

    if #params.completeMaps == 0 then
        return false
    end

    local __change_to_laizi = function(completeMaps, changeIndex)
        
        local __groups_change_to_laizi = function(groups, changeInfo)
            for j = 1, #groups do
                local cards = groups[j]
                for i = 1, #cards do
                    if cards[i] == changeInfo[2] then
                        cards[i] = -1
                        return true
                    end
                end
            end
            
            return false
        end

        for i = 1, #changeIndex do

            for j = 1, #completeMaps do

                local item = completeMaps[j]

                if __groups_change_to_laizi(item.jiang, changeIndex[i]) or
                __groups_change_to_laizi(item.ke, changeIndex[i]) or
                __groups_change_to_laizi(item.shun, changeIndex[i]) then
                end

            end

        end

    end

    local completeMaps = {}

    for i = 1, #params.completeMaps do

        local item = params.completeMaps[i]

        __change_to_laizi(item, params.changeIndexs[i])

        for j = 1, #item do
            table.insert(completeMaps, item[j])
        end

    end

    return #completeMaps > 0, completeMaps
end


local function checkThree(mahjong,handcards,cardCount,start,grpIdx,mark,groupIdxs,laiziCount,resultInfo,lastCard,postman)
	if resultInfo.isFullCheck == false and resultInfo.success == true then
		return true
	end
	
	for i=start,cardCount do
		if mark[i] ~= true then
			if i+2 <= cardCount then
				local j1 = getSameSeqIdx(handcards,cardCount,i+1,handcards[i],mark)
				if j1 > 0 then
					local j2 = getSameSeqIdx(handcards,cardCount,j1+1,handcards[i],mark)
					if j2 > 0 then
						setGroupIndex(i,j1,j2,true,mark,groupIdxs,grpIdx)
						local tmpResult = checkThree(mahjong,handcards,cardCount,i+1,grpIdx+1,mark,groupIdxs,laiziCount,resultInfo,lastCard,postman)
						setGroupIndex(i,j1,j2,nil,mark,groupIdxs,nil)
						if resultInfo.isFullCheck == false and tmpResult == true then
							return true
						end
					end
				end
			end

			local k1 = getNextSeqIdx(handcards,cardCount,i+1,handcards[i],mark)
			if k1 > 0 then
				local k2 = getNextSeqIdx(handcards,cardCount,k1+1,handcards[k1],mark)
				if k2 > 0 then
					setGroupIndex(i,k1,k2,true,mark,groupIdxs,grpIdx)
					local tmpResult = checkThree(mahjong,handcards,cardCount,i+1,grpIdx+1,mark,groupIdxs,laiziCount,resultInfo,lastCard,postman)
					setGroupIndex(i,k1,k2,nil,mark,groupIdxs,nil)
					if resultInfo.isFullCheck == false and tmpResult == true then
						return true
					end
				end
			end
		end
	end

    local unUseCards = getUnuseCards(handcards,cardCount,mark)

	local result,completeMaps
	--[[
    if g_REGION_CONFIG.lua_laizi_incomplete_check_level == 1 then
        result,completeMaps = check_incomplete(mahjong,laiziCount,postman,unUseCards)
    elseif g_REGION_CONFIG.lua_laizi_incomplete_check_level == 2 then
        result,completeMaps = get_incomplete_full_comb(unUseCards,laiziCount)
    elseif g_REGION_CONFIG.lua_laizi_incomplete_check_level == 3 then
        result,completeMaps = get_incomplete_full_comb_wenshan(unUseCards,mahjong)
    end]]
    dump(unUseCards,"TerryTan unUseCards");
    result,completeMaps = get_incomplete_full_comb_wenshan(unUseCards,mahjong)
	if result == true then
       dump(completeMaps,"TerryTan complete");
		--[[
        for i = 1, #completeMaps do
            resultInfo.groups = {}
		    makeGroups(handcards,cardCount,groupIdxs,completeMaps[i],resultInfo.groups)
		    local isHu,weight,isBest = region_hu.is_hu_at_end(mahjong,lastCard,postman,resultInfo.groups)
		    weight = weight or 0
		    isBest = isBest or false
		    if not resultInfo.tmp_weight then
			    resultInfo.tmp_weight = -1
		    end
		    if isHu and weight > resultInfo.tmp_weight then
			    resultInfo.success = true
			    mahjong.groups = resultInfo.groups
				
			    resultInfo.tmp_weight = weight
			    if isBest then
				    resultInfo.isFullCheck = false
                    break
			    end
		    end
        end]]
	end

	return resultInfo.success ==  true
end

local function complete(mahjong,handcards,laiziCount,lastCard,postman)
	local cardCount = #handcards
	local mark = {}
	local groupIdxs = {}
	local resultInfo = {}
	resultInfo.isFullCheck = postman.isFullHuCheck or false
	checkThree(mahjong,handcards,cardCount,1,1,mark,groupIdxs,laiziCount,resultInfo,lastCard,postman)
	return resultInfo
end

complete({},{1,2,3,4,5,6,7,8,9,50,50,52},2,52,{}) ;