local upvaluehelper = require("hooks/upvaluehelper")
local SpDamageUtil = require("components/spdamageutil")

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

--
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

   if inst.shield_cd == nil then
       local fx = SpawnPrefab("elixir_player_forcefield")
       inst:AddChild(fx)
       inst.SoundEmitter:PlaySound("dontstarve/characters/wendy/abigail/shield/on")

        inst.components.health.externalreductionmodifiers:RemoveModifier(inst, "forcefield")

        --  不屈药剂和复仇药剂 减伤效果    
        local debuff = GetDeBuff(inst)
       if debuff.potion_tunings.playerreatliate then
           local hitrange = 5
           local damage = TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE
           debuff.ignore = {}

           local x, y, z = inst.Transform:GetWorldPosition()

           for i, v in ipairs(TheSim:FindEntities(x, y, z, hitrange, COMBAT_TARGET_TAGS, NO_TAGS_NO_PLAYERS)) do
               if not debuff.ignore[v] and
                   v:IsValid() and
                   v.entity:IsVisible() and
                   v.components.combat ~= nil then
                   local range = hitrange + v:GetPhysicsRadius(0)
                   if v:GetDistanceSqToPoint(x, y, z) < range * range then
                       if inst.owner ~= nil and not inst.owner:IsValid() then
                           inst.owner = nil
                       end
                       if inst.owner ~= nil then
                           if inst.owner.components.combat ~= nil and
                               inst.owner.components.combat:CanTarget(v) and
                               not inst.owner.components.combat:IsAlly(v)
                           then
                               debuff.ignore[v] = true
                               local retaliation = SpawnPrefab("abigail_retaliation")
                               retaliation:SetRetaliationTarget(v)
                               --V2C: wisecracks make more sense for being pricked by picking
                               --v:PushEvent("thorns")
                           end
                       elseif v.components.combat:CanBeAttacked() then
                           -- NOTES(JBK): inst.owner is nil here so this is for non worn things like the bramble trap.
                           local isally = false
                           if not inst.canhitplayers then
                               --non-pvp, so don't hit any player followers (unless they are targeting a player!)
                               local leader = v.components.follower ~= nil and v.components.follower:GetLeader() or nil
                               isally = leader ~= nil and leader:HasTag("player") and
                                   not (v.components.combat ~= nil and
                                       v.components.combat.target ~= nil and
                                       v.components.combat.target:HasTag("player"))
                           end
                           if not isally then
                               debuff.ignore[v] = true
                               v.components.combat:GetAttacked(inst, damage, nil, nil, inst.spdmg)
                               local retaliation = SpawnPrefab("abigail_retaliation")
                               retaliation:SetRetaliationTarget(v)
                               --v:PushEvent("thorns")
                           end
                       end
                   end
               end
           end
       end

       inst.shield_cd = inst:DoTaskInTime(10 + math.random(2, 4), function()            
            if inst.components.health ~= nil then
                inst.components.health.externalreductionmodifiers:SetModifier(inst, inst:HasTag("player") and TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_REDUCTION or
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
		end,
		ONDETACH_PLAYER = function(inst, target)
            target.components.combat.externaldamagemultipliers:RemoveModifier(inst)
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

-- -- 夜影万金油人物上buff 功能重写
-- AddPrefabPostInit("ghostvision_buff", function(inst)
--     if not TheWorld.ismastersim then
--         return inst
--     end

--     local debuff = inst.components.debuff
--     if debuff ~= nil then
--         -- buff 添加
--         debuff.onattachedfn = function(inst, target)
--             inst.entity:SetParent(target.entity)
--             inst.Transform:SetPosition(0, 0, 0)

--             inst:ListenForEvent("death", function()
--                 inst.components.debuff:Stop()
--             end, target)

--             if target.prefab == "wendy" then
--                 target.components.combat.damagemultiplier = 1
--             else
--                 target.components.combat.damagemultiplier = target.components.combat.damagemultiplier + 0.1
--             end
--         end

--         -- buff 移除
--         debuff.ondetachedfn = function(inst, target)
--             if target ~= nil and target:IsValid() then
--                 if target.prefab == "wendy" then
--                     target.components.combat.damagemultiplier = 0.75
--                 else
--                     target.components.combat.damagemultiplier = target.components.combat.damagemultiplier - 0.1
--                 end
--             end
--         end
--     end
-- end)


