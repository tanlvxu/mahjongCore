local Group = class("Group",GameObject)

--存在的癞子的时候，无法通过对比值来判断类型
Group.TYPE_JIANG = 1
Group.TYPE_KE = 2
Group.TYPE_SHUN = 3

function Group:ctor()
	self.m_elems = {}
	self.m_type = 0
end

--外部不能直接调用m_type来判断类型，一定要通过isKe,isShun,isJiang方法，才是准确的
function Group:setType(type)
	self.m_type = type
end

function Group:addTwo(c1,c2)
	table.insert(self.m_elems,c1)
	table.insert(self.m_elems,c2)
end

function Group:addThree(c1,c2,c3)
	table.insert(self.m_elems,c1)
	table.insert(self.m_elems,c2)
	table.insert(self.m_elems,c3)
end

function Group:size()
	return #self.m_elems
end

function Group:first()
	return self.m_elems[1]
end

function Group:second()
	return self.m_elems[2]
end

function Group:third()
	return self.m_elems[3]
end

function Group:isKe()
	local size = #self.m_elems

    if size ~= 3 then
        return false
    end

    if self.m_type == Group.TYPE_KE then
        return true
    end

    if self.m_type == 0 and self.m_elems[2] == -1 and self.m_elems[3] == -1 then
        return true
    end

    if self.m_elems[1] == self.m_elems[2] and self.m_elems[2] == self.m_elems[3] then
        return true
    end

    return false
end

function Group:isShun()

    local size = #self.m_elems

    if size ~= 3 then
        return false
    end

    if self.m_type == Group.TYPE_SHUN then
        return true
    end

    if self.m_type == 0 and self.m_elems[2] == -1 and self.m_elems[3] == -1 then
        return true
    end

    if self.m_type == 0 and (self.m_elems[1] + 1 == self.m_elems[2]) and (self.m_elems[2] + 1) == self.m_elems[3] then
        return true
    end

    return false

end
	
function Group:isJiang()
	local size = #self.m_elems
	return size == 2 and self.m_elems[1] == self.m_elems[size] or self.m_type == Group.TYPE_JIANG
end

--判断是否有癞子
--@return bool
function Group:hasLaizi()
	for _,v in ipairs(self.m_elems) do
		if v==-1 then
			return true
		end
	end
	return false
end

function Group:allSame()
    local first = self:first();
    for _,v in ipairs(self.m_elems) do
        if v ~= first then
            return false
        end
    end
    return true
end

function Group:getElems()
	return self.m_elems
end

function Group:clone()
	local g = new(Group)
	g.m_type = self.m_type
	g:addThree(self.m_elems[1],self.m_elems[2],self.m_elems[3])
	return g
end

function Group:toString()
	return string.format("Group ==> size:%d, first:0x%02x, second:0x%02x, third:0x%02x, isKe:%s, isShun:%s, isJiang:%s",
									self:size(),self:first(),self:second(),self:third() or 0,
									tostring(self:isKe()),tostring(self:isShun()),tostring(self:isJiang()))
end
return Group