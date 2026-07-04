-- 阿比多药剂小图标显示
modimport("scripts/postinit/components/pethealthbar")
modimport("scripts/postinit/widgets/pethealthbadge")
modimport("scripts/postinit/widgets/statusdisplays")

-- hook 库导入
local upvaluehelper = require("hooks/upvaluehelper")

local function ShadowFX_Start(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local xoffset = math.random(-10, 10) / 10
    local zoffset = math.random(-10, 10) / 10
    if not inst.inlimbo and not inst.sg:HasStateTag("busy") then
    --SpawnPrefab("minotaur_blood"..math.random(3)).Transform:SetPosition(x + xoffset, y, z + zoffset)
        SpawnPrefab("cane_ancient_fx").Transform:SetPosition(x + xoffset, y, z + zoffset)
    end
end

-- 重置任务
local function reset_cd(inst)
    if inst.abigail_attack_stack ~= 0 then
        inst.abigail_attack_stack = 0
    end
    
    inst.components.planardamage:SetBaseDamage(5)
end

local function reset_resist(inst)
    inst.components.damagetyperesist.targets = {}
end

-- 攻击特效
local function onattackother(inst, data)
    -- 取消已有任务并重新计时
    if inst.abigail_attack_task then
        inst.abigail_attack_task:Cancel()  -- 取消正在进行的倒计时
        inst.abigail_attack_task = nil
    end

    -- 无动作10秒后重置
    inst.abigail_attack_task = inst:DoTaskInTime(10, reset_cd)
    -- 增伤效果
    if inst.abigail_attack_stack < 10 then
        local planardamage = inst.components.planardamage
        planardamage:SetBaseDamage( 5 + inst.abigail_attack_stack*2 )
 
        -- 累加攻击次数
        inst.abigail_attack_stack = inst.abigail_attack_stack + 1
    end
    
    -- -- 添加减伤效果
    local victim = data.target
    local combat = victim.components.combat
    if inst and combat then
        if victim.abigail_target_resist then
            victim.abigail_target_resist:Cancel()
            victim.abigail_target_resist = nil
        end

        victim:AddTag("abigail_target_resist")
        victim.abigail_target_resist = victim:DoTaskInTime(10, function()
            victim:RemoveTag("abigail_target_resist")
            inst.components.damagetyperesist:RemoveResist("abigail_target_resist", inst, "abigail_target_resist")
        end)

        -- 
        local resist = inst.components.damagetyperesist:GetResistForTag("abigail_target_resist")
        print("减伤效果:", resist)
        if resist > 0.5 then
            inst.components.damagetyperesist:AddResist("abigail_target_resist", inst, math.max((resist - 0.1), 0.5), "abigail_target_resist")
        end
    end
end

-- 暗影药剂效果
local function SetToShadow(inst, isreload)
    local x,y,z = inst.Transform:GetWorldPosition()
    local skilled = inst.components.follower and 
                    inst.components.follower.leader and 
                    inst.components.follower.leader.components.skilltreeupdater and 
                    inst.components.follower.leader.components.skilltreeupdater:IsActivated("wendy_shadow_3") or nil


    inst.SoundEmitter:PlaySound("meta5/abigail/abigail_nightmare_buff_stinger")
    SpawnPrefab("abigail_attack_shadow_fx").Transform:SetPosition(x,y,z)

    -- 特效1
    local fx = SpawnPrefab("abigail_shadow_buff_fx")
    inst:AddChild(fx)
    
    -- 特效2
    local fx2 = SpawnPrefab("shadow_puff_large_front")
    fx2.Transform:SetScale(1.2,1.2,1.2)
    fx2.Transform:SetPosition(x,y,z)
    
    -- 同步一下
    if inst.components.aura and inst.components.aura.applying then
        inst:PushEvent("stopaura")
        inst:PushEvent("startaura")
    end

    -- 易伤效果 && 减伤效果
    if skilled or isreload then
        inst.shadowstate = true

        -- 改变形态为暗影阿比
        inst.AnimState:SetBuild("ghost_abigail_shadow_build")
        
        -- 添加位面伤害 初始值为5
        inst.components.planardamage:SetBaseDamage(5)

        -- 减伤效果
        if inst.components.damagetyperesist == nil then
            inst:AddComponent("damagetyperesist")
        end

        inst:ListenForEvent("onareaattackother", onattackother)
    end
end

-- 暗影阿比恢复常态
local function SetShadowToNormal(inst)
    -- 移除易伤效果
    if inst.shadowstate then
        inst.shadowstate = false

        -- 形态恢复
        inst.AnimState:SetBuild("ghost_abigail_build")

        -- 特效1
        local fx = SpawnPrefab("shadow_puff_large_front")
        fx.Transform:SetScale(1.2, 1.2, 1.2)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

        -- 移除监听
        inst:RemoveEventCallback("onareaattackother", onattackother)

        -- 恢复位面伤害
        inst.components.planardamage:SetBaseDamage(0)
    end
    
    -- 同步一下
    if inst.components.aura and inst.components.aura.applying then
        inst:PushEvent("stopaura")
        inst:PushEvent("startaura")
    end
end

local function SetMaxHealth(inst)
    local health = inst.components.health
    if health then
        if health:IsDead() then
            health.maxhealth = inst.base_max_health + inst.bonus_max_health
        else
            local health_percent = health:GetPercent()
            health:SetMaxHealth(inst.base_max_health + inst.bonus_max_health)
            health:SetPercent(health_percent, true)
        end

        if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil then
            inst._playerlink.components.pethealthbar:SetMaxHealth(health.maxhealth)
        end
    end
end

local function SetToGestalt(inst)
    print("SetToGestalt")
    inst:AddTag("gestalt")
    inst.components.aura:Enable(false)
    inst.AnimState:SetBuild("ghost_abigail_gestalt_build")

    -- inst.AnimState:OverrideSymbol("fx_puff2",       "lunarthrall_plant_front",      "fx_puff2")
    -- inst.AnimState:OverrideSymbol("v1_ball_loop",   "brightmare_gestalt",   "v1_ball_loop")
    -- inst.AnimState:OverrideSymbol("v1_embers",      "brightmare_gestalt",   "v1_embers")
    -- inst.AnimState:OverrideSymbol("v1_melt2",       "brightmare_gestalt",   "v1_melt2")

    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat.attackrange = 6

    local buff = inst.components.debuffable:GetDebuff("super_elixir_buff")

    if buff ~= nil and buff.prefab == "ghostlyelixir_lunar_buff" then
        inst.components.planardamage:RemoveBonus(buff, "ghostlyelixir_lunarbonus")
        inst.components.planardamage:AddBonus(buff, TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS_GESTALT, "ghostlyelixir_lunarbonus")
    end

end

local function SetToNormal(inst)
    print("SetToNormal")
    inst:RemoveTag("gestalt")
    inst.components.aura:Enable(true)
    inst.AnimState:SetBuild("ghost_abigail_build")

    inst.components.combat:SetAttackPeriod(4)
    inst.components.combat.attackrange = 3

    local buff = inst.components.debuffable:GetDebuff("super_elixir_buff")

    if buff ~= nil and buff.prefab == "ghostlyelixir_lunar_buff" then
        inst.components.planardamage:RemoveBonus(buff, "ghostlyelixir_lunarbonus")
        inst.components.planardamage:AddBonus(buff, TUNING.SKILLS.WENDY.LUNARELIXIR_DAMAGEBONUS, "ghostlyelixir_lunarbonus")
    end
end
-- 

local function UpdateGhostlyBondLevel(inst, level)
	local max_health = level == 4 and TUNING.ABIGAIL_HEALTH_LEVEL4
                    or level == 3 and TUNING.ABIGAIL_HEALTH_LEVEL3
					or level == 2 and TUNING.ABIGAIL_HEALTH_LEVEL2
					or TUNING.ABIGAIL_HEALTH_LEVEL1

    inst.base_max_health = max_health

	SetMaxHealth(inst)

	local light_vals = TUNING.ABIGAIL_LIGHTING[level] or TUNING.ABIGAIL_LIGHTING[1]
	if light_vals.r ~= 0 then
		inst.Light:Enable(not inst.inlimbo)
		inst.Light:SetRadius(light_vals.r)
		inst.Light:SetIntensity(light_vals.i)
		inst.Light:SetFalloff(light_vals.f)
	else
		inst.Light:Enable(false)
	end
    inst.AnimState:SetLightOverride(light_vals.l)
end

local function OnDebuffAdded(inst, name, debuff)
    if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil then
        -- print("OnDebuffAdded", name)
        -- 显示治疗药剂技能图标
        if name == "ghostly_healing_buff" then
            inst._playerlink.components.pethealthbar:SetSymbol3(debuff.prefab)
        -- 显示位面药剂技能图标
        elseif name == "super_elixir_buff"then
            inst._playerlink.components.pethealthbar:SetSymbol2(debuff.prefab)
        -- 显示额外药剂技能图标
        elseif name == "elixir_extra_buff" then
            inst._playerlink.components.pethealthbar:SetSymbol1(debuff.prefab)
        -- 显示药剂技能图标
        elseif name == "elixir_buff" then            
            inst._playerlink.components.pethealthbar:SetSymbol(debuff.prefab)
        end
    end
end

local function OnDebuffRemoved(inst, name, debuff)
    if inst._playerlink ~= nil and inst._playerlink.components.pethealthbar ~= nil then
        -- 移除治疗药剂技能图标
        if name == "ghostly_healing_buff" then
            inst._playerlink.components.pethealthbar:SetSymbol3(0)
        -- 移除位面药剂技能图标
        elseif name == "super_elixir_buff" then
            inst._playerlink.components.pethealthbar:SetSymbol2(0)
        -- 移除额外药剂技能图标
        elseif name == "elixir_extra_buff" then
            inst._playerlink.components.pethealthbar:SetSymbol1(0)
        -- 移除药剂技能图标
        elseif name == "elixir_buff" then            
            inst._playerlink.components.pethealthbar:SetSymbol(0)
        end
	end
end


-- DSV uses 4 but ignores physics radius
local NO_TAGS_NO_PLAYERS =	{ "INLIMBO", "notarget", "noattack", "wall", "player", "companion", "playerghost" }
local COMBAT_TARGET_TAGS = { "_combat" }
local ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ = TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW * TUNING.ABIGAIL_DEFENSIVE_MAX_FOLLOW
local function OnAttacked(inst, data)
    local combat = inst.components.combat
    if data.attacker == nil then
        combat:SetTarget(nil)
    elseif not data.attacker:HasTag("noauradamage") then
        -- If we're blocking targets and our target is still valid, don't switch away automatically.
        local is_blocking_retargets = inst.components.timer:TimerExists("block_retargets")
        if not is_blocking_retargets or not combat:IsValidTarget(combat.target) then
            if not inst.is_defensive then
                combat:SetTarget(data.attacker)
            elseif inst:IsWithinDefensiveRange() and inst._playerlink:GetDistanceSqToInst(data.attacker) < ABIGAIL_DEFENSIVE_MAX_FOLLOW_DSQ then
                combat:SetTarget(data.attacker)
            end
        end
    end
end

-- 阿比盖尔
AddPrefabPostInit("abigail", function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    -- 攻击次数
    inst.abigail_attack_stack = 0

    -- 移除掉pre_health_setval监听事件
    local pre_health_setval = upvaluehelper.GetEventHandle(inst, "pre_health_setval", "prefabs/abigail")
    if pre_health_setval then
        inst:RemoveEventCallback("pre_health_setval", pre_health_setval)
    end

    -- 重写attacked监听事件
    local attacked = upvaluehelper.GetEventHandle(inst, "attacked", "prefabs/abigail")
    if attacked then
        inst:RemoveEventCallback("attacked", attacked)
        inst:ListenForEvent("attacked", OnAttacked)
    end

    inst.SetToShadow = SetToShadow
    inst.SetShadowToNormal = SetShadowToNormal
    inst.SetMaxHealth = SetMaxHealth
    inst.SetToGestalt = SetToGestalt
    inst.SetToNormal = SetToNormal
    inst.UpdateGhostlyBondLevel = UpdateGhostlyBondLevel


    -- 重写UpdateGhostlyBondLevel  -- 升级4级阿比盖尔
    local OldUpdateGhostlyBondLevel = upvaluehelper.Get(inst.LinkToPlayer, "UpdateGhostlyBondLevel", "prefabs/abigail")
    if OldUpdateGhostlyBondLevel then
        upvaluehelper.Set(inst.LinkToPlayer, "UpdateGhostlyBondLevel", UpdateGhostlyBondLevel)
    end

    -- 重写debuffable  -- 小图标
    if inst.components.debuffable then
        inst.components.debuffable.ondebuffadded = OnDebuffAdded
        inst.components.debuffable.ondebuffremoved = OnDebuffRemoved
    end

    -- 重写一下LinkToPlayer  -- 修复两种药剂buff同时生效的问题
    local _oldLinkToPlayer = inst.LinkToPlayer
    inst.LinkToPlayer = function(inst, player)
        if inst:GetDebuff("elixir_extra_buff") then
            player.components.pethealthbar:SetSymbol1(inst:GetDebuff("elixir_extra_buff").prefab)
        elseif inst:GetDebuff("ghostly_healing_buff") then
            player.components.pethealthbar:SetSymbol3(inst:GetDebuff("ghostly_healing_buff").prefab)
        end
        _oldLinkToPlayer(inst, player)
    end

    -- 阿比盖尔可以攻击影怪
    inst._sanitychange = function(inst, en)
        if en then
            inst:AddTag("crazy")
        else
            inst:RemoveTag("crazy")
        end
    end

    -- 重写OnSave
    local old_OnSave = inst.OnSave
    inst.OnSave = function(inst, data)
        data.shadowstate = inst.shadowstate
        if old_OnSave then
            old_OnSave(inst, data)
        end
    end

    -- 重写Onload
    inst.OnLoad = function(inst, data) 
        if data ~= nil then
            if data.gestalt then
                inst:SetToGestalt()
            elseif data.shadowstate then
                SetToShadow(inst,  data.shadowstate)
            end

            -- if data.bonus_max_health then
            --     inst.bonus_max_health = data.bonus_max_health
            -- end
        end
    end

end)