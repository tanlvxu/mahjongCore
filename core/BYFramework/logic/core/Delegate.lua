local Delegate = {}
 
local next = next
local unpack = unpack
local t = {
	remove = table.remove,
	insert = table.insert,
	indexOf = function(list, value)
		local n = 0
		for k,v in next, list do 
			if v == value then
				return k;
			end
		end
		return -1;
	end
}

local meta = {
     __add = function(x, y)
        if type(y) == "function" then
            t.insert(x, y)
            return x
        elseif type(y) == "table" then
            for i=1,#y do
                if type(y[i]) == "function" then t.insert( x, y[i] ) end
            end
            return x
        end
    end,
    __sub = function(x, y)
        if type(y) == "function" then
            local index = t.indexOf( x, y )
            if index > -1 then t.remove( x, index ) end
            return x
        elseif type(y) == "table" then
            for i=#y,1,-1 do
                local index = t.indexOf( x, y[i] )
                if index > -1 then t.remove( x, index ) end
            end
            return x
        end
    end,
    __call = function(d, ...)
        for i,v in next, d do
            v(...)
        end
    end
}

local meta2 = {
    __add = meta.__add,
    __sub = meta.__sub,
    __call = function( d, ... )
        local result = arg or {}
        for i,v in next, d do
            result = { v( unpack(result) ) }
        end

        return unpack(result)
    end
}

function Delegate.newDelegate( bool )
    local d = {}
    --bool==false, use same arguments for every function
    --bool==true, will pass retrun result to next function
    setmetatable(d, bool and meta2 or meta)
    return d
end


return Delegate;