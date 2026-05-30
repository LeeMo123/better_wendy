-- buff type 获取
local function GetBufftype(inst, target)
    local elixirbuff = target:GetDebuff("elixir_buff")
    local elixirextrabuff = target:GetDebuff("elixir_extra_buff")

    local has_skill = false
    if target.components.skilltreeupdater and target.components.skilltreeupdater:IsActivated("wendy_potion_yield") then
        has_skill = true
    elseif target._playerlink and target._playerlink.components.skilltreeupdater and target._playerlink.components.skilltreeupdater:IsActivated("wendy_potion_yield") then
        has_skill = true
    end

    print("has_skill", has_skill)
    print("is attack_buff", inst.buff_prefab == "ghostlyelixir_attack_buff")
    print("elixirbuff", elixirbuff and elixirbuff.prefab == inst.buff_prefab)

    if  elixirbuff == nil                                                       -- 当前作用对象没有上任何buff       
        or not has_skill                                                        -- 当前作用对象没有技能   
        or inst.buff_prefab == "ghostlyelixir_attack_buff"                      -- 当前作用对象已经上了攻击药剂
        or (elixirbuff and elixirbuff.prefab == inst.buff_prefab) 
    then                                                                        -- 当前作用对象已经上了同药剂
        return "elixir_buff"
    end

    if not elixirextrabuff                                                      -- 当前作用对象没有占用elixir_extra_buff
        or elixirbuff.prefab == inst.buff_prefab                                -- 同药剂替换2 
    then 
        return "elixir_extra_buff" 
    end                 

    local shield = inst.potion_tunings.shield_prefab        -- 如果是护盾药剂时特殊处理；
    if shield then                                          -- 两种护盾是上/下位药剂，优先相互替换
        if elixirbuff.potion_tunings.shield_prefab then return "elixir_buff" end
        if elixirextrabuff.potion_tunings.shield_prefab then return "elixir_extra_buff" end
    end

    -- 否则替换当前剩余时间短的药剂buff
    return elixirbuff.components.timer:GetTimeLeft("decay") < elixirextrabuff.components.timer:GetTimeLeft("decay") and "elixir_buff" or "elixir_extra_buff"
end

-- 所有药剂种类
-- TUNING.GHOSTLYELIXIRS
local function Doapplyelixer(inst, giver, target)
    -- 位面药剂和两种治疗药剂独立出来
    local buff_type = inst.potion_tunings.super_elixir and "super_elixir_buff" or inst.potion_tunings.ghostly_healing and "ghostly_healing_buff" or nil

    -- 获取buff类型
    if buff_type == nil then
        buff_type = GetBufftype(inst, target)
    end

    local buff = target:AddDebuff(buff_type, inst.buff_prefab, nil, nil, function()
        local cur_buff = target:GetDebuff(buff_type)
        if cur_buff ~= nil and cur_buff.prefab ~= inst.buff_prefab then
            target:RemoveDebuff(buff_type)
        end
    end)

    if buff ~= nil then
        local new_buff = target:GetDebuff(buff_type)
        new_buff:buff_skill_modifier_fn(giver, target)
        return buff
    end
end

if next(TUNING.GHOSTLYELIXIRS) then
    for _, ghostlyelixir in pairs(TUNING.GHOSTLYELIXIRS) do
        AddPrefabPostInit(ghostlyelixir, function(inst)
            if not TheWorld.ismastersim then
                return inst
            end

            inst.components.ghostlyelixir.doapplyelixerfn = Doapplyelixer
        end)
    end
end
