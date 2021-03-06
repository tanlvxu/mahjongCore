--[[--
癞子全检测算法
@author tlx
]]
--require("mahjongCore.core.BYFramework._load");
--require("mahjongCore.core.BYFramework.logic.demo.profiler");
--local utils,NROWS,NCOLS = unpack(import(".utils"))
require("BYFramework._load");
require("BYFramework.logic.demo.profiler");
require("coroutine");
local utils,NROWS,NCOLS = unpack(import("utils"))
local Group = import("group")
local change = {"wan","tong","tiao","feng"}

local function make_three_group(type,c1,c2,c3)
  local group = new(Group)
  group:addThree(c1,c2,c3)
  group:setType(type)
  return group
end

local function make_two_group(type,c1,c2)
  local group = new(Group)
  group:addTwo(c1,c2)
  group:setType(type)
  return group
end

local combine_jiang_and_shun_ke;
local combine_shun_ke ;
combine_jiang_and_shun_ke = function(handcards,cardsGroup,start,groups,laiziCount,cardsCount,cardIndex,hasJiang,lineCount)
    local cards = cardsGroup[change[start]] ;
    for i=cardIndex,#cards do
    	  local card = cards[i] ;
          local num = cardsCount[card] ;
          if num > 1 then
             cardsCount[card] = cardsCount[card] - 2;
             table.insert(groups,make_two_group(Group.TYPE_JIANG,card,card)) ;
             lineCount = lineCount - 2 ;
             combine_shun_ke(handcards,cardsGroup,start,groups,laiziCount,cardsCount,1,hasJiang,lineCount);
             lineCount = lineCount + 2 ;
             table.remove(groups) ;
             cardsCount[card] = cardsCount[card] + 2;
          end
             cardsCount[card] = cardsCount[card] - 1;
             laiziCount = laiziCount - 1 ;
             table.insert(groups,make_two_group(Group.TYPE_JIANG,card,-1)) ;
             lineCount = lineCount -1 ;
             combine_shun_ke(handcards,cardsGroup,start,groups,laiziCount,cardsCount,1,hasJiang,lineCount);
             table.remove(groups) ;
             laiziCount = laiziCount + 1 ; 
             lineCount = lineCount + 1 ;
             cardsCount[card] = cardsCount[card] + 1;
    end
end


local removeCards = function(cardsCount,cards)
   local removetablecards = function(tb)
        for k,v in pairs(tb.m_elems) do
         if v ~= -1 then
           cardsCount[v] = cardsCount[v] - 1 ;
         end
        end
   end

  if cards[1] and type(cards[1]) == "table" then 
      for i=1,#cards do
        removetablecards(cards[i])
      end
  else
      removetablecards(cards)
  end
end

local addCards = function(cardsCount,cards)
  local addtablecards = function(tb)
      for k,v in pairs(tb.m_elems) do
        if v~= -1 then
         cardsCount[v] = cardsCount[v] + 1 ;
        end
      end
  end
  if cards[1] and type(cards[1]) == "table" then 
      for i=1,#cards do
        addtablecards(cards[i])
      end
  else
      addtablecards(cards)
  end 
end

local function getSameShun(currentIndex,cards,cardsCount)
	 local groups = {} ;
	 local card  = cards[currentIndex] ;
   local needLaiziCount = 0 ;
   while cardsCount[card] > 0 do
     local group = {};
     if cards[currentIndex+1] == card +1  then
        if cards[currentIndex+2] == card + 2 and cardsCount[card + 2] > 0 then
            if  cardsCount[card + 1] >0 then 
               group = make_three_group(Group.TYPE_SHUN,card,card+1,card+2); --{card,card+1,card+2} ;
            else
               group = make_three_group(Group.TYPE_SHUN,card,card+2,-1) --{card,card+2,-1} ;
               needLaiziCount = needLaiziCount + 1 ;
            end
        elseif cardsCount[card + 1] >0 then
              group = make_three_group(Group.TYPE_SHUN,card,card+1,-1) --{card,card+1,-1} ;
              needLaiziCount = needLaiziCount + 1 ;
        else
              group = make_three_group(Group.TYPE_SHUN_OR_KE,card,-1,-1) --{card,-1,-1} ;
              needLaiziCount = needLaiziCount + 2 ;
        end
     elseif cards[currentIndex+1] == card +2 and cardsCount[card + 2] > 0  then
          group = make_three_group(Group.TYPE_SHUN,card,-1,card+2) --{card,-1,card+2 } ;
          needLaiziCount = needLaiziCount + 1 ;
     else
          group = make_three_group(Group.TYPE_SHUN_OR_KE,card,-1,-1) --{card,-1,-1} ;
          needLaiziCount = needLaiziCount + 2 ;
     end   
      removeCards(cardsCount,group);
      table.insert(groups,group);
   end
   
    return groups,needLaiziCount ;
end


local function getSameKe(currentIndex,cards,cardsCount)
     local group = nil ;
	 local card  = cards[currentIndex] ;
     if cardsCount[card] == 2 then
        group = make_three_group(Group.TYPE_KE,card,card,-1);           --{card,card,-1} ;
        removeCards(cardsCount,group)
        return 1,group ;
     end
     if cardsCount[card] == 3 then
        group = make_three_group(Group.TYPE_KE,card,card,card);         --{card,card,card} ;
        removeCards(cardsCount,group)
        return 0,group ;
     end
     return -1 
end

local function insertTb(groups,group)
    if group[1] and type(group[1]) == "table" then
       for i = 1 ,#group do 
          table.insert(groups,group[i]); 
       end
    else
       table.insert(groups,group) ;
    end
end

local function removeTb(groups,group)
    if group[1] and type(group[1]) == "table" then
       for i =1,#group do
       table.remove(groups);
       end
    else
       table.remove(groups) ;
    end
end



combine_shun_ke = function(handcards,cardsGroup,start,groups,laiziCount,cardsCount,cardIndex,hasJiang,lineCount)
    local cards = cardsGroup[change[start]] ;

    if  lineCount == 0 then
       checkThree(handcards,cardsGroup,start+1,groups,laiziCount,cardsCount,hasJiang)
    end
    local add_after_remove = function(leaveLaiziNum,group,i)
        if not group then return false ;end
        local groupLen = 3
        if group[1] and type(group[1]) == "table" then groupLen = #group * 3 end ;
        if leaveLaiziNum > 0 then
         laiziCount = laiziCount - leaveLaiziNum ; 
         lineCount = lineCount - groupLen + leaveLaiziNum ;
        else
         lineCount = lineCount - groupLen  ;
        end ;  
        if laiziCount < 0 then laiziCount = laiziCount + leaveLaiziNum; 
          lineCount =  lineCount + groupLen - leaveLaiziNum ;
          addCards(cardsCount,group);
          return false ;
        end
        insertTb(groups,group);
        combine_shun_ke(handcards,cardsGroup,start,groups,laiziCount,cardsCount,i+1,hasJiang,lineCount);
       
        if leaveLaiziNum > 0 then 
          laiziCount = laiziCount + leaveLaiziNum ;
          lineCount =  lineCount + groupLen - leaveLaiziNum ;
        else
          lineCount =  lineCount + groupLen  ;
        end ;
        if group then  
          addCards(cardsCount,group);
          removeTb(groups,group);
        end
    end
	local cards = cardsGroup[change[start]] ;
    for i=cardIndex,#cards do
    	local card = cards[i] ;
        local num = cardsCount[card] ;
        if num > 0 then
           do
           local leaveLaiziNum,group = getSameKe(i,cards,cardsCount)
            --   dump(group,"group1");
              add_after_remove(leaveLaiziNum,group,i);
           end
        if groups[1] and groups[1].m_elems[1] == 17 then
             dump(group,"group2");
            end
             --    dump(groups,"TerryTan complete");
           if start == 4 then --风牌箭牌走自己的逻辑

               
           else
           do          
           local group,leaveLaiziNum = getSameShun(i,cards,cardsCount) ;
            if groups[1] and groups[1].m_elems[1] == 17 then
             dump(group,"group1");
            end
              add_after_remove(leaveLaiziNum,group,i);
           end
           end
        end       
    end
end


local function getLineCount(cardsCount,cardsGroup,start)
    local cards = cardsGroup[change[start]] ;
    local num = 0 ;
    for k,v in ipairs(cards) do
      if cardsCount[v] then
         num = num + cardsCount[v] ;
      end
    end
    return num ;
end

local function __simple_check(start,cardsGroup,laiziCount,cardsCount,hasJiang)

    local needLaiziCount = 0
    for i = start,4 do
    local count = getLineCount(cardsCount,cardsGroup,i);
      if count % 3 ~= 0 then
        needLaiziCount = needLaiziCount + 3 - (count % 3)
      end
    end
    
    if needLaiziCount > laiziCount and hasJiang then
        return true
    end
    if not hasJiang and (needLaiziCount-laiziCount)%3 >  1 then
        return true ;
    end
    return false
end


--[[
  顺刻检测算法
]]
 checkThree = function(handcards,cardsGroup,start,groups,laiziCount,cardsCount,hasJiang)

      if start > 4 then
      local needRemoveCount = 0 ;
      if not hasJiang then
          if  laiziCount /3 == 2 then
             table.insert(groups,make_two_group(Group.TYPE_JIANG,-1,-1));
             laiziCount = laiziCount - 2 ;
             needRemoveCount = needRemoveCount + 1;
          else
            return ;
          end
      
      end
      
      if laiziCount>0 and laiziCount%3 == 0 then
         for i = 1,laiziCount/3 do
             table.insert(groups,make_three_group(Group.TYPE_SHUN_OR_KE,-1,-1,-1) );
         end
         needRemoveCount = needRemoveCount + laiziCount/3 ;
         laiziCount = 0 ;
      end

       if laiziCount > 0 then
        return
       end
        
       for i=1,needRemoveCount do
        table.remove(groups);
       end
        --找到一组就返回
        dump(groups,"TerryTan complete");
       -- coroutine.yield(true);
        return ;
      end

      if laiziCount < 0 or __simple_check(start,cardsGroup,laiziCount,cardsCount,hasJiang) then
           return false ;
      end
      
      if cardsGroup[change[start]] and #cardsGroup[change[start]] == 0 then
         checkThree(handcards,cardsGroup,start+1,groups,laiziCount,cardsCount,hasJiang)
         return ;
      end
      if not hasJiang then
         combine_jiang_and_shun_ke(handcards,cardsGroup,start,groups,laiziCount,cardsCount,1,true,getLineCount(cardsCount,cardsGroup,start)) 
         combine_shun_ke(handcards,cardsGroup,start,groups,laiziCount,cardsCount,1,hasJiang,getLineCount(cardsCount,cardsGroup,start))
      else
         combine_shun_ke(handcards,cardsGroup,start,groups,laiziCount,cardsCount,1,hasJiang,getLineCount(cardsCount,cardsGroup,start))
      end
     
end 


--[[-- 
将麻将子分到四种
]]
local function allocateCards(cardsGroup,handcards,cardsCount)
    for k,v in ipairs(handcards) do
    	cardsCount[v] = cardsCount[v] or 0 ;
    	cardsCount[v] = cardsCount[v] + 1 ;
        local row,col = utils.get_suits_face(v);
        if row == 0 then
        	if cardsCount[v] == 1 then 
            table.insert(cardsGroup["wan"],v)
            end
        elseif row == 1 then
        	if cardsCount[v] == 1 then 
            table.insert(cardsGroup["tong"],v)
            end
        elseif row == 2 then
            if cardsCount[v] == 1 then 
            table.insert(cardsGroup["tiao"],v)
            end
        else
        	if cardsCount[v] == 1 then 
        	table.insert(cardsGroup["feng"],v)
       	    end
        end
    end
end


local function complete(mahjong,handcards,laiziCount,lastCard,postman)

	local cardCount = #handcards
	local cardsGroup = {wan={},tong={},tiao={},feng={}} --将麻将子分为4种
	local cardsCount = {} --将麻将子分为4种
	local groups = {} ;
	allocateCards(cardsGroup,handcards, cardsCount);
  --开启协程
	coroutine.resume(coroutine.create(checkThree),handcards,cardsGroup,1,groups,laiziCount,cardsCount,false);
	return resultInfo
  end

  profiler = newProfiler("call")
  profiler:start()
--  complete({},{1,2,3,4,5,6,6,6,7,7,8,8,9,9},0,{}) ;
  complete({},{1,2,3,4,5,6,7,8,9,17,17,18,19},1,{}) ;
  local outfile = io.open( "profile2.txt", "w+" )
  profiler:report( outfile )
  outfile:close()
