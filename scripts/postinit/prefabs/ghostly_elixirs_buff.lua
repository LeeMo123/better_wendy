local upvaluehelper = require("hooks/upvaluehelper")
local SpDamageUtil = require("components/spdamageutil")

-- 夜视修改
modimport("scripts/postinit/prefabs/ghostvision_buff")

---------------------
--- 月亮阿比
---------------------

-- 判断是否处于被召唤的状态
local function IsAbigailSummoned(target)
    return target._playerlink ~= nil 
        and target._playerlink.components.ghostlybond ~= nil 
        and target._playerlink.components.ghostlybond.summoned 
        and target._playerlink.components.ghostlybond.ghost == target
end

-- 月亮药剂效果
local function SetToLunar(inst)
    local skilled = inst.components.follower and 
                    inst.components.follower.leader and 
                    inst.components.follower.leader.components.skilltreeupdater and 
                    inst.components.follower.leader.components.skilltreeupdater:IsActivated("wendy_lunar_3") or nil
    
    if skilled then
        if not IsAbigailSummoned(inst) then
            inst:SetToGestalt(inst)
        else
            inst:ChangeToGestalt(true)
        end
    end
end

-- 月亮阿比变成普通形态
local function SetGestaltToNormal(inst)
    if inst:HasTag("gestalt") then
        inst:SetToNormal(inst)
    end
end

---------------------
--- 暗影阿比
---------------------

local function SetToShadow(inst)
    inst:SetToShadow(false)
end

local function SetShadowToNormal(inst)
    inst:SetShadowToNormal()
end

---------------------
--- 不屈药剂&&复仇药剂buff
---------------------

local function GetDeBuff(inst)
    if inst:GetDebuff("elixir_buff") and inst:GetDebuff("elixir_buff").potion_tunings.shield_prefab then
        return inst:GetDebuff("elixir_buff")
    elseif inst:GetDebuff("elixir_extra_buff") and inst:GetDebuff("elixir_extra_buff").potion_tunings.shield_prefab then
        return inst:GetDebuff("elixir_extra_buff")
    end
end

-- DSV uses 4 but ignores physics radius
local NO_TAGS_NO_PLAYERS =	{ "INLIMBO", "notarget", "noattack", "wall", "player", "companion", "playerghost" }
local COMBAT_TARGET_TAGS = { "_combat" }

local onattacked_shield = function(inst, data)
    if data.redirected then
        return
    end

    local debuff = GetDeBuff(inst)
    --  复仇药剂反伤效果    
    if debuff.potion_tunings.playerreatliate then
        if data.attacker ~= nil and data.attacker.components.combat ~= nil then
            data.attacker.components.combat:GetAttacked(inst, TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE)
            SpawnPrefab("abigail_retaliation"):SetRetaliationTarget(data.attacker)
        end
    end

    if inst.shield_cd == nil then
        if inst:HasTag("abigail") then
            inst:AddDebuff("forcefield", debuff ~= nil and debuff.potion_tunings.shield_prefab or "abigailforcefield")
        else
            local fx = SpawnPrefab("elixir_player_forcefield")
            inst:AddChild(fx)
            inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")
        end

        inst.components.health.externalreductionmodifiers:RemoveModifier(inst, "forcefield")

        inst.shield_cd = inst:DoTaskInTime(13, function()
            if inst.components.health ~= nil then
                inst.components.health.externalreductionmodifiers:SetModifier(inst,
                    inst:HasTag("player") and TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_REDUCTION or
                        debuff.potion_tunings.playerreatliate and 150 or 100, "forcefield")
            end

            inst.shield_cd:Cancel()
            inst.shield_cd = nil
        end)
    end
end


local buffs = {
    -- 光之怒buff重写
    ghostlyelixir_lunar_buff = {
        onattachedfn = function(inst, target)
            SetToLunar(target)
        end,
        ondetachedfn = function(inst, target)
            SetGestaltToNormal(target)
        end,
        onextended = function(inst, target)
            SetToLunar(target)
        end,
    },

    -- 诅咒之苦bUFF重写
    ghostlyelixir_shadow_buff = {
        onattachedfn = function(inst, target)
            SetToShadow(target)
        end,
        ondetachedfn = function(inst, target)
            SetShadowToNormal(target)
        end,
        onextended = function(inst, target)
            SetToShadow(target)
        end,
    },

    -- 不屈药剂buff重写
    ghostlyelixir_shield_buff = {
        ONAPPLY_PLAYER = function(inst, target)
            if target.components.health ~= nil then
                target.components.health.externalreductionmodifiers:SetModifier(target, TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_REDUCTION, "forcefield")
            end

            target:ListenForEvent("attacked", onattacked_shield)
        end,

        ONDETACH_PLAYER = function(inst, target)
            target:RemoveEventCallback("attacked", onattacked_shield)
            if target.shield_cd ~= nil then
                target.shield_cd:Cancel()
                target.shield_cd = nil
            end

            if target.components.health ~= nil then
                target.components.health.externalreductionmodifiers:RemoveModifier(target, "forcefield")
            end
        end,

        ONAPPLY = function(inst, target)
            target.components.health.externalreductionmodifiers:SetModifier(target, 100, "forcefield")
            
            target:ListenForEvent("attacked", onattacked_shield)
        end,

        ONDETACH = function(inst, target)
            target:RemoveEventCallback("attacked", onattacked_shield)
            if target.shield_cd ~= nil then
                target.shield_cd:Cancel()
                target.shield_cd = nil
            end

            if target.components.health ~= nil then
                target.components.health.externalreductionmodifiers:RemoveModifier(target, "forcefield")
            end

            target:RemoveEventCallback("attacked", onattacked_shield)
        end,
    },

    -- 蒸馏复仇buff重写
    ghostlyelixir_retaliation_buff = {
        ONAPPLY_PLAYER = function(inst, target)
            if target.components.health ~= nil then
                target.components.health.externalreductionmodifiers:SetModifier(target, TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_REDUCTION, "forcefield")
            end

            target:ListenForEvent("attacked", onattacked_shield)
        end,

        ONDETACH_PLAYER = function(inst, target)
            target:RemoveEventCallback("attacked", onattacked_shield)
            if target.shield_cd ~= nil then
                target.shield_cd:Cancel()
                target.shield_cd = nil
            end

            if target.components.health ~= nil then
                target.components.health.externalreductionmodifiers:RemoveModifier(target, "forcefield")
            end
        end,

        
        ONAPPLY = function(inst, target)
            target.components.health.externalreductionmodifiers:SetModifier(target, 150, "forcefield")

            target:ListenForEvent("attacked", onattacked_shield)
        end,

        ONDETACH = function(inst, target)
            target:RemoveEventCallback("attacked", onattacked_shield)
            if target.shield_cd ~= nil then
                target.shield_cd:Cancel()
                target.shield_cd = nil
            end

            if target.components.health ~= nil then
                target.components.health.externalreductionmodifiers:RemoveModifier(target, "forcefield")
            end
        end,
    },

    -- 夜影万金油buff重写
    ghostlyelixir_attack_buff = {
        ONAPPLY_PLAYER = function(inst, target)
            target.components.combat.externaldamagemultipliers:SetModifier(inst, 1.1)

			if not target:HasDebuff("ghostvision_buff") then
				target.components.talker:Say(GetString(target, "ANNOUNCE_ELIXIR_GHOSTVISION"))
			end
			target:AddDebuff("ghostvision_buff","ghostvision_buff")
		end,
		ONDETACH_PLAYER = function(inst, target)
            target.components.combat.externaldamagemultipliers:RemoveModifier(inst)

            if target:GetDebuff("ghostvision_buff") then
                target:RemoveDebuff("ghostvision_buff")
            end
		end,
    },

    -- 恐怖经历药剂buff重写
    ghostlyelixir_revive_buff = {
        ONAPPLY = function(inst, target)
			if target.components.follower.leader and target.components.follower.leader.components.ghostlybond then
				target.components.follower.leader.components.ghostlybond:SetBondLevel(target.components.follower.leader.components.ghostlybond.maxbondlevel)
			end
		end,
    },

    -- 强健精油药剂buff重写
    ghostlyelixir_speed_buff = {
		ONAPPLY_PLAYER = function(inst, target)
            if target.components.talker ~= nil then
                target.components.talker:Say(GetString(target, "ANNOUNCE_ELIXIR_PLAYER_SPEED")) 
            end
            target:AddTag("strong_for_heavy")
		end,
		ONDETACH_PLAYER = function(inst, target)
            target:RemoveTag("strong_for_heavy")
		end,
    }
}

-- buff重写
for buff_name, data in pairs(buffs) do
    AddPrefabPostInit(buff_name, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        -- 角色应用buff效果
        if data.ONAPPLY_PLAYER then
            inst.potion_tunings.ONAPPLY_PLAYER = data.ONAPPLY_PLAYER
        end

        -- 角色取消buff效果
        if data.ONDETACH_PLAYER then
            inst.potion_tunings.ONDETACH_PLAYER = data.ONDETACH_PLAYER
        end

        -- 鬼魂应用效果
        if data.ONAPPLY then
            inst.potion_tunings.ONAPPLY = data.ONAPPLY
        end

        -- 鬼魂取消效果
        if data.ONDETACH then
            inst.potion_tunings.ONDETACH = data.ONDETACH
        end

        -- buff
        local debuff = inst.components.debuff
        if debuff ~= nil then
            -- buff 开始
            local _onattachedfn = debuff.onattachedfn
            debuff.onattachedfn = function(inst, target)
                if data.onattachedfn ~= nil then
                    data.onattachedfn(inst, target)
                end

                if _onattachedfn ~= nil then
                    _onattachedfn(inst, target)
                    -- buff效果死亡后仍保留  -- 仅针对位面药剂
                    if table.contains({"ghostlyelixir_lunar_buff", "ghostlyelixir_shadow_buff"}, inst.prefab) then
                        local death = upvaluehelper.GetEventHandle(inst, "death", "prefabs/ghostly_elixirs")
                        if death ~= nil then
                            inst:RemoveEventCallback("death", death, target)
                        end
                    end
                end
            end

            -- buff 结束
            local _ondetachedfn = debuff.ondetachedfn
            debuff.ondetachedfn = function(inst, target)
                if data.ondetachedfn ~= nil then
                    data.ondetachedfn(inst, target)
                end

                if _ondetachedfn ~= nil then
                    _ondetachedfn(inst, target)
                end
            end

            -- buff 延续
            local _onextendedfn = debuff.onextendedfn
            debuff.onextendedfn = function(inst, target)
                if data.onextended ~= nil then
                    data.onextended(inst, target)
                end

                if _onextendedfn ~= nil then
                    _onextendedfn(inst, target)
                end
            end

        end
    end)
end

-- -- 药剂重写
-- local ghostlyelixir_table = {
--     wendy_shadow_2 = "ghostlyelixir_shadow",        -- 暗影药剂
--     wendy_lunar_2 = "ghostlyelixir_lunar",          -- 光之怒药剂

--     -- wendy_potion_revive = "ghostlyelixir_revive",   -- 恐怖经历药剂
-- }

-- -- 遍历处理每个药水prefab，修改使用药剂时需要对应的技能点
-- for skill_id, elixir_prefab in pairs(ghostlyelixir_table) do
--     AddPrefabPostInit(elixir_prefab, function(inst)
--         if not TheWorld.ismastersim then
--             return inst
--         end

--         local _doapplyelixerfn = inst.components.ghostlyelixir.doapplyelixerfn
--         inst.components.ghostlyelixir.doapplyelixerfn = function(inst, giver, target)
--             if giver ~= nil and giver.components.skilltreeupdater ~= nil and
--                 giver.components.skilltreeupdater:IsActivated(skill_id) then
--                 -- 调用原逻辑
--                 if _doapplyelixerfn ~= nil then
--                     return _doapplyelixerfn(inst, giver, target)    -- 这里需要return才能生效
--                 end
--             end
--         end
--     end)
-- end
-- --  
-- local function damagemultiplier_change(inst)
--     local phase = TheWorld.state.phase
--     inst.components.combat.damagemultiplier = phase == "night" and 1.05 or phase == "dusk" and 0.95 or 0.85
-- end