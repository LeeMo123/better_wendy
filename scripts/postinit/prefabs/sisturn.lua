local upvaluehelper = require("hooks/upvaluehelper")

-- 判断是否满
local function isfull(inst)
    return inst.components.container and inst.components.container:IsFull()
end

-- 花朵
local flowers = {}
local function flowers_change(inst, isfull, doer)
    -- 检查容器内的物品
    flowers = inst.components.container:GetAllItems()
end

-- 监听里边的物品获取
local function itemgetfn(inst, data)
    local flower = data and data.item
    local doer = inst.components.container.currentuser
	local skilltreeupdater = (doer and doer.components.skilltreeupdater) or nil
    
    if flower ~= nil then
        -- 花腐烂后掉落物哀悼荣耀
        if skilltreeupdater and skilltreeupdater:IsActivated("wendy_sisturn_1") then
            flower.components.perishable.onperishreplacement = "ghostflower"
            flower._ghostflower = true
        end
    end
end

-- flower 丢失
local function itemlosefn(inst, data)
    local flower = data and data.prev_item
    if flower ~= nil  then 
        -- 取出后，恢复放入花朵的腐烂掉落物
        if flower.components.perishable.onperishreplacement == "ghostflower" then
            flower.components.perishable.onperishreplacement = "spoiled_food"
            flower._ghostflower = false
        end
    end
end

-- 姐妹骨灰盒 修改
AddPrefabPostInit("sisturn", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    -- 监听里边的物品获取和丢失事件
    inst:ListenForEvent("itemget", itemgetfn)
    inst:ListenForEvent("itemlose", itemlosefn)
end)
