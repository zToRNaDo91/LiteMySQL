---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by iTexZ.
--- DateTime: 12/06/2020 19:04
---

print(string.format('^2[LiteMySQL]^7 : Started'))

---@class Lite;
local Lite = {};

---Logs
---@param Executed number
---@param Message string
---@return void
---@public
function Lite:Logs(Executed, Message)
    local Started = Executed;
    print(string.format('[%s] [LiteMySQL] [%sms] : %s^7', os.date("%Y-%m-%d %H:%M:%S", os.time()), string.gsub((Started - GetGameTimer()) + 100, '%-', ''), Message))
end

---[[ LiteMySQL Class ]]---

---@class Query;
local LiteMySQL = {};

---@class Select;
local Select = {};

---@class Where;
local Where = {}

---Insert
---
--- Insert database content.
---
---@param Table string
---@param Content table
---@return number
function LiteMySQL:Insert(Table, Content)
    local executed = GetGameTimer();
    self.fields = "";
    self.keys = "";
    self.id = nil;
    for key, _ in pairs(Content) do
        self.fields = string.format('%s`%s`,', self.fields, key)
        key = string.format('@%s', key)
        self.keys = string.format('%s%s,', self.keys, key)
    end
    MySQL.Async.insert(string.format("INSERT INTO %s (%s) VALUES (%s)", Table, string.sub(self.fields, 1, -2), string.sub(self.keys, 1, -2)), Content, function(insertId)
        self.id = insertId;
    end)
    while (self.id == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^2INSERT %s', Table))
    if (self.id ~= nil) then
        return self.id;
    else
        error("InsertId is nil")
    end
end

---Update
---
--- Update database table content with simple where condition
---
---@param Table string
---@param Column string
---@param Operator string
---@param Value any
---@param Content table
---@return table
---@public
function LiteMySQL:Update(Table, Column, Operator, Value, Content)
    local executed = GetGameTimer();
    self.affectedRows = nil;
    self.keys = "";
    self.args = {};
    for key, _ in pairs(Content) do
        self.keys = string.format("%s`%s` = @%s, ", self.keys, key, key)
    end
    for key, value in pairs(Content) do
        self.args[string.format('@%s', key)] = value;
    end
    self.args['@value'] = Value;
    local query = string.format("UPDATE %s SET %s WHERE %s %s @value", Table, string.sub(self.keys, 1, -3), Column, Operator, Value)
    MySQL.Async.execute(query, self.args, function(affectedRows)
        self.affectedRows = affectedRows;
    end)
    while (self.affectedRows == nil) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^4UPDATED %s', Table))
    if (self.affectedRows ~= nil) then
        return self.affectedRows;
    end
end

---Select
---@return Select
---@param Table string
---@public
function LiteMySQL:Select(Table)
    self.SelectTable = Table
    return Select;
end

---GetSelectTable
---@public
function LiteMySQL:GetSelectTable()
    return self.SelectTable;
end

---All
---@return any
---@private
function Select:All()
    local executed = GetGameTimer();
    local storage = {};
    MySQL.Async.fetchAll(string.format('SELECT * FROM %s', LiteMySQL:GetSelectTable()), { }, function(result)
        if (result ~= nil) then
            storage = result
        end
    end)
    while (#storage == 0) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^5SELECTED ALL %s', LiteMySQL:GetSelectTable()))
    return #storage, storage;
end

---Delete
---@param Column string
---@param Operator string
---@param Value string
---@return number
---@private
function Select:Delete(Column, Operator, Value)
    local executed = GetGameTimer();
    local count = 0;
    MySQL.Async.execute(string.format('DELETE FROM %s WHERE %s %s @value', LiteMySQL:GetSelectTable(), Column, Operator), { ['@value'] = Value }, function(affectedRows)
        count = affectedRows
    end)
    while (count == 0) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^8DELETED %s WHERE %s %s %s', LiteMySQL:GetSelectTable(), Column, Operator, Value))
    return count;
end

---GetWhereResult
---@return table
---@public
function Select:GetWhereResult()
    return self.whereStorage;
end

---GetWhereConditions
---@return table
---@public
function Select:GetWhereConditions()
    return self.whereConditions;
end

---Where
---@param Column string
---@param Operator string
---@param Value string
---@return Where
---@public
function Select:Where(Column, Operator, Value)
    local executed = GetGameTimer();
    self.whereStorage = {};
    self.whereConditions = Column, Operator, Value;
    MySQL.Async.fetchAll(string.format('SELECT * FROM %s WHERE %s %s @value', LiteMySQL:GetSelectTable(), Column, Operator), { ['@value'] = Value }, function(result)
        if (result ~= nil) then
            table.insert(self.whereStorage, result)
        end
    end)
    while (#self.whereStorage == 0) do
        Citizen.Wait(1.0)
    end
    Lite:Logs(executed, string.format('^5SELECTED %s WHERE %s %s %s', LiteMySQL:GetSelectTable(), Column, Operator, Value))
    return Where;
end

---Update
---@param Content table
---@return void
---@public
function Where:Update(Content)
    if (self:Exists()) then
        local Table = LiteMySQL:GetSelectTable();
        local Column, Operator, Value = Select:GetWhereConditions();
        LiteMySQL:Update(Table, Column, Operator, Value, Content)
    else
        error('Not exists')
    end
end

---Exists
---@return boolean
---@public
function Where:Exists()
    return Select:GetWhereResult() ~= nil and #Select:GetWhereResult() >= 1
end

---Get
---@return any
---@public
function Where:Get()
    local result = Select:GetWhereResult();
    return #result, result;
end

--[[
RegisterCommand('LiteMySQL', function()
    MySQL.ready(function()

        local affectedRows = LiteMySQL:Update('players_settings', 'uuid', '=', 'sex', {
            menus = json.encode({ style = 'SS', sound = 'RageUI' })
        });

        LiteMySQL:Insert('players_settings', {
            uuid = 'sex',
            menus = json.encode({ test = true });
            keyboard_binds = json.encode({ test = true });
            approach = "Oui argent";
        })

        LiteMySQL:Select('players_settings'):Where('uuid', '=', 'sex'):Update({
            menus = json.encode({ style = 'xxxx', sound = 'RageUI' })
        })

        local count, result = LiteMySQL:Select('players_settings'):All()

        local count, result = LiteMySQL:Select('players_settings'):Where('uuid', '=', 'b7d4b94c-8581-440a-ab52-b442c8b6d3ea'):Get();

        local exists = LiteMySQL:Select('players_settings'):Where('uuid', '=', 'b7d4b94c-8581-440a-ab52-b442c8b6d3ea'):Exists();

        local count = LiteMySQL:Select('players_settings'):Delete('uuid', '=', 'sex')

        LiteMySQL:Select('players_settings'):Where('uuid', '=', 'b7d4b94c-8581-440a-ab52-b442c8b6d3ea'):Update({

        })

        local count, result = LiteMySQL:Select('items'):All()
        print("Count = " .. count)
        local insertedID = LiteMySQL:Insert('items', {
            label = 'Label test',
            name = 'name test',
            limit = 20,
            weight = 200,
        })

    end)
end)
]]--
