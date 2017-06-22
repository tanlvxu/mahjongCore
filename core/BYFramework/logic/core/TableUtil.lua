local TableUtil = { };

function TableUtil.merge(t1, t2)
    local t = { };
    for _, v in ipairs(t1) do
        t[#t + 1] = v;
    end
    for _, v in ipairs(t2) do
        t[#t + 1] = v;
    end
    return t;
end

function TableUtil.selectValue(tbl, filter)
    assert(type(tbl) == "table", "t must be a table");
    for i, v in ipairs(tbl) do
        if filter and filter(i, v) then
            return i, v;
        end
    end
end

function TableUtil.selectValues(tbl, filter)
    assert(type(tbl) == "table", "t must be a table");
    local t = { };
    for i, v in ipairs(tbl) do
        if filter and filter(i, v) then
            t[#t + 1] = v;
        end
    end
    return t;
end

function TableUtil.selectElement(tbl, filter)
    assert(type(tbl) == "table", "t must be a table");
    for k, v in pairs(tbl) do
        if filter and filter(k, v) then
            return k, v;
        end
    end
end

function TableUtil.selectElements(tbl, filter)
    assert(type(tbl) == "table", "t must be a table");
    local t = {};
    for k, v in pairs(tbl) do
        if filter and filter(k, v) then
            t[k] = v;
        end
    end
    return t;
end

function TableUtil.isEqual(t1, t2, ignore_mt)
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
    -- as well as tables which have the metamethod __eq
    local mt = getmetatable(t1)
    if not ignore_mt and mt and mt.__eq then return t1 == t2 end
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil or not TableUtil.isEqual(v1, v2) then return false end
    end
    for k2, v2 in pairs(t2) do
        local v1 = t1[k2]
        if v1 == nil or not TableUtil.isEqual(v1, v2) then return false end
    end
    return true
end

function TableUtil.randomList(t, num)
    local randomList = { }
    num = num or #t;

    if num > #t then
        num = #t;
    end

    local rangeList = { };
    for i = 1, num do
        rangeList[i] = t[i]
    end

    for i = 1, num do
        local index = math.random(i, #rangeList);
        rangeList[i], rangeList[index] = rangeList[index], rangeList[i];
        randomList[i] = rangeList[i];
    end

    return randomList;
end

-- tinsertvalues(t, [pos,] values)
-- similar to table.insert but inserts values from given table "values",
-- not the object itself, into table "t" at position "pos".
-- note: an optional extension is to allow selection of a slice of values:
--   tinsertvalues(t, [pos, [vpos1, [vpos2, ]]] values)
-- DavidManura, public domain, http://lua-users.org/wiki/TableUtils
--[[ tests:
  local t = {5,6,7}
  tinsertvalues(t, {8,9})
  tinsertvalues(t, {})
  tinsertvalues(t, 1, {1,4})
  tinsertvalues(t, 2, {2,3})
  assert(table.concat(t, '') == '123456789')
--]]
function TableUtil.insertValues(t, ...)
    local pos, values
    if select('#', ...) == 1 then
        pos, values = #t + 1, ...
    else
        pos, values = ...
    end
    if #values > 0 then
        for i = #t, pos, -1 do
            t[i + #values] = t[i]
        end
        local offset = 1 - pos
        for i = pos, pos + #values - 1 do
            t[i] = values[i + offset]
        end
    end
end

local function val_to_str(v, level)
    if level == 0 then
        return "*Max val Level*";
    end
    if "string" == type(v) then
        v = string.gsub(v, "\n", "\\n")
        if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
            return "'" .. v .. "'"
        end
        return '"' .. string.gsub(v, '"', '\\"') .. '"'
    elseif type(v) == "UserData" then
        return "UserData";
    elseif type(v) == "table" then
        local mt = getmetatable(v);
        if mt and mt.__tostring then
            return tostring(v);
        else
            return TableUtil.tostring(v, level);
        end
    else
        return tostring(v);
    end
end

local function key_to_str(k, level)
    if level == 0 then
        return "*Max key Level*";
    end
    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
        return k
    else
        return "[" .. val_to_str(k, level) .. "]"
    end
end

function TableUtil.tostring(tbl, level)
    level = level or 10;
    if level == 0 then
        return "*Max Level*";
    end
    local result, done = { }, { }
    for k, v in ipairs(tbl) do
        table.insert(result, val_to_str(v, level - 1))
        done[k] = true
    end
    for k, v in pairs(tbl) do
        if not done[k] then
            table.insert(result,
            key_to_str(k, level - 1) .. "=" .. val_to_str(v, level - 1))
        end
    end
    return "{" .. table.concat(result, ",") .. "}"
end

function TableUtil.getValue(tbl, ...)
    local arg = {...}
    local t = tbl;
    for i, v in ipairs( arg ) do
        if t[v] then
            t = t[v];
        else
            return;
        end
    end
    return t;
end

function TableUtil.getSubset(t, from, to)
    assert(from > 0 and from <= to and to <= #t, string.format("invalid range : %d, %d", from, to));
    local sub = {}
    for i=from,to do
        sub[#sub + 1] = t[i]
    end
    return sub
end

return TableUtil;