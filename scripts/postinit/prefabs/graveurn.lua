-- 灵魂容器
local function DoFunnyIdle(inst)
    local rand = math.random(3)

    if rand == 1 then
        inst.AnimState:PlayAnimation("idle_pre")
        inst.AnimState:PushAnimation("idle", false)
        inst.AnimState:PushAnimation("idle_pst", false)
        inst.AnimState:PushAnimation("idle_empty")

    elseif rand == 2 then
        inst.AnimState:PlayAnimation("idle_2_pre")
        inst.AnimState:PushAnimation("idle_2", false)
        inst.AnimState:PushAnimation("idle_2_pst", false)
        inst.AnimState:PushAnimation("idle_empty")

    elseif rand == 3 then
        inst.AnimState:PlayAnimation("idle_pre")
        inst.AnimState:PushAnimation("idle_3", false)
        inst.AnimState:PushAnimation("idle_pst", false)
        inst.AnimState:PushAnimation("idle_empty")
    end

    inst.funnyidletask = inst:DoTaskInTime(7 + 5 * math.random(), DoFunnyIdle)
end

local function OnEntityWake(inst)
    if inst:IsInLimbo() or inst:IsAsleep() or inst.components.finiteuses:GetUses() == 0 then
        return
    end

    if inst.funnyidletask ~= nil then
        inst.funnyidletask:Cancel()
        inst.funnyidletask = nil
    end

    inst.funnyidletask = inst:DoTaskInTime(7 + 5 * math.random(), DoFunnyIdle)
end

local function OnEntitySleep(inst)
    if inst.funnyidletask ~= nil then
        inst.funnyidletask:Cancel()
        inst.funnyidletask = nil

        inst.AnimState:PlayAnimation("idle_empty")
    end
end

---------------------------------------------------------------------------------------------------
local function GetStatus(inst)
    return inst.components.finiteuses ~= nil and inst.components.finiteuses.current > 0 and "HAS_SPIRIT" or nil
end
---------------------------------------------------------------------------------------------------

-- 贴图更改
local function percentusedchange(inst, data)
    if data.percent ~= 0 then
        inst.components.inventoryitem:ChangeImageName("graveurn")
    else
        inst.components.inventoryitem:ChangeImageName("graveurn_empty")
    end
end

---------------------------------------------------------------------------------------------------

-- local function OnSave(inst, data)
--     data.grave_record = inst._grave_record
-- end

-- local function OnLoad(inst, data)
--     if data == nil or data.grave_record == nil then
--         return
--     end
-- end

---------------------------------------------------------------------------------------------------

AddPrefabPostInit("graveurn", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
    
    if inst.components.gravedigger ~= nil then
        inst:RemoveComponent("gravedigger")
    end

    if inst.components.finiteuses == nil then
        inst:AddComponent("finiteuses")
    end
    inst.components.finiteuses:SetMaxUses(5)
    inst.components.finiteuses:SetUses(0)
    inst.components.finiteuses:SetOnFinished()  -- 耐久为零不为空
    inst.components.finiteuses:SetDoesNotStartFull(true) 

    inst:ListenForEvent("percentusedchange", percentusedchange)
    
    -- 检查状态
    inst.components.inspectable.getstatus = GetStatus
    
    inst:ListenForEvent("exitlimbo", OnEntityWake)   -- 离开 Limbo 状态（如丢到地面）时触发唤醒
    inst:ListenForEvent("enterlimbo", OnEntitySleep) -- 进入 Limbo 状态（如捡起）时停止动画
end)