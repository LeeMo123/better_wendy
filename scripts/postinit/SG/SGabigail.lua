local upvaluehelper = require("hooks/upvaluehelper")

-- 添加 idle_custom 动画
local function newgetidleanim(inst)
    if not inst.components.timer:TimerExists("flicker_cooldown") and
        math.random() < 0.2 and 
        TheWorld.components.sisturnregistry and 
        TheWorld.components.sisturnregistry:IsActive() and 
        inst.is_defensive and inst.components.combat.target == nil and
        not inst.shadowstate then
        
        inst.components.timer:StartTimer("flicker_cooldown", math.random()*20  + 10 )

        return "idle_abigail_flicker"
    end

    return (inst._is_transparent and "abigail_escape_loop")
        or (inst.components.aura.applying and "attack_loop")
        or (inst.is_defensive and math.random() < 0.1 and "idle_custom")
        or "idle"
end

local function UpdateFlash(target, data, id, r, g, b)
    if data.flashstep < 4 then
        local value = (data.flashstep > 2 and 4 - data.flashstep or data.flashstep) * 0.05
        if target.components.colouradder == nil then
            target:AddComponent("colouradder")
        end
        target.components.colouradder:PushColour(id, value * r, value * g, value * b, 0)
        data.flashstep = data.flashstep + 1
    else
        target.components.colouradder:PopColour(id)
        data.task:Cancel()
    end
end

local function StartFlash(inst, target, r, g, b)
    local data = {
        flashstep = 1
    }
    local id = inst.prefab .. "::" .. tostring(inst.GUID)
    data.task = target:DoPeriodicTask(0, UpdateFlash, nil, data, id, r, g, b)
    UpdateFlash(target, data, id, r, g, b)
end

local function GestaltDoAttack(inst, target, debuff)
    inst.components.combat:DoAttack(target)
    if debuff then
        inst:ApplyDebuff({
            target = target
        })
    end

    if target.components.combat and target.components.combat.hiteffectsymbol then
        local fx = SpawnPrefab("abigail_gestalt_hit_fx")
        fx.entity:SetParent(target.entity)
        target:AddChild(fx)
        inst.SoundEmitter:PlaySound("meta5/abigail/gestalt_abigail_dashattack_hit")
        StartFlash(inst, target, 1, 1, 1)
    end
end

local GESTALT_ATTACKAT_RADIUS_PADDING = 1

local GESTALT_DASH_ATTACK_MUST_TAGS = {"_combat", "_health"}
local REGISTERED_GESTALT_DASH_ATTACK_TAGS = {"INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost",
                                             "FX", "NOCLICK", "DECOR", "companion", "player", "wall"}

local function SGAbigail(sg)
    ---------------------------------------------
    sg.states["gestalt_loop_attack"] = State {
        name = "gestalt_loop_attack",
        tags = {"busy", "nointerrupt", "swoop", "noattack"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.Physics:Stop()
            inst:SetTransparentPhysics(true)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:SetMotorVelOverride(15, 0, 0)

            inst.AnimState:PlayAnimation("gestalt_attack_loop", true)
            inst.sg:SetTimeout(3)

            inst.sg.statemem.oldattackdamage = inst.components.combat.defaultdamage

            local buff = inst:GetDebuff("elixir_buff") and inst:GetDebuff("elixir_buff").prefab == "ghostlyelixir_attack_buff" or
                    inst:GetDebuff("elixir_extra_buff") and inst:GetDebuff("elixir_extra_buff").prefab == "ghostlyelixir_attack_buff" or nil

            local phase = buff and "night" or
                              TheWorld.state.phase
            local damage = (TUNING.ABIGAIL_GESTALT_DAMAGE[phase] or TUNING.ABIGAIL_GESTALT_DAMAGE.day)

            inst.sg.statemem.attack_damage = damage
            inst.components.combat:SetDefaultDamage(damage)

            inst.components.combat:StartAttack()
            inst.sg.statemem.enable_attack = true
            inst.sg.statemem.attacked_targets = {}
        end,

        ontimeout = function(inst)
            inst.sg.statemem.enable_attack = false
        end,

        onupdate = function(inst)
            if inst.components.combat.target and inst.components.combat.target:IsValid() and
                inst.sg.statemem.enable_attack then
                local x, y, z = inst.components.combat.target.Transform:GetWorldPosition()
                inst:ForceFacePoint(x, y, z)
            end

            if inst.sg.statemem.enable_attack then
                local target = inst.components.combat.target
                if target ~= nil and target ~= inst and target:IsValid() and inst:GetDistanceSqToInst(target) <=
                    TUNING.GESTALT_ATTACK_HIT_RANGE_SQ and inst.components.combat:CanTarget(target) then
                    -- 原主目标攻击 --
                    inst.components.combat:SetDefaultDamage(inst.sg.statemem.attack_damage)
                    GestaltDoAttack(inst, target, true)
                    inst.sg.statemem.enable_attack = false
                    if inst.sg.statemem.attacked_targets ~= nil and inst.sg.statemem.attacked_targets[target] ~= nil then
                        inst.sg.statemem.attacked_targets[target] = true
                    end
                end
            end

            -- 新增路径范围伤害 -- 
            local x, y, z = inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, GESTALT_ATTACKAT_RADIUS_PADDING, GESTALT_DASH_ATTACK_MUST_TAGS,
                REGISTERED_GESTALT_DASH_ATTACK_TAGS)

            for _, hittable_entity in pairs(ents) do
                if hittable_entity:IsValid() and hittable_entity ~= inst and -- 排除自身
                    inst.components.combat:CanTarget(hittable_entity) and
                    not inst.sg.statemem.attacked_targets[hittable_entity] then
                        
                    inst.components.combat:SetDefaultDamage(inst.sg.statemem.attack_damage / 3)
                    GestaltDoAttack(inst, hittable_entity, false) -- 修复参数传递
                    inst.sg.statemem.attacked_targets[hittable_entity] = true
                end
            end

            -- 结束新增内容 --
            if (inst.sg.statemem.enable_attack == false or inst.components.combat.target == nil or
                not inst.components.combat.target:IsValid() or inst.components.combat.target.components.health:IsDead()) and
                not inst.end_gestalt_attack_task then
                inst.end_gestalt_attack_task = inst:DoTaskInTime(0.5, function()
                    inst.sg:GoToState("gestalt_pst_attack")
                end)
            end
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
            inst.sg.statemem.enable_attack = false

            if inst.end_gestalt_attack_task then
                inst.end_gestalt_attack_task:Cancel()
                inst.end_gestalt_attack_task = nil
            end

            if inst.sg.statemem.oldattackdamage then
                inst.components.combat.defaultdamage = inst.sg.statemem.oldattackdamage
            end

            inst:SetTransparentPhysics(false)
        end
    }
    ---------------------------------------------
    -- 发呆状态无敌 无法受到攻击
    local gestalt_pst_attack_tag = sg.states["gestalt_pst_attack"] and sg.states["gestalt_pst_attack"].tag
    if gestalt_pst_attack_tag ~= nil then
        gestalt_pst_attack_tag = {"busy", "nointerrupt", "swoop", "noattack"}
    else
        print("gestalt_pst_attack_tag nil")
    end

    ---------------------------------------------  

    -- 改写阿比盖尔待机动画
    local getidleanim = upvaluehelper.Get(sg.states["idle"].onenter, "getidleanim", "stategraphs/SGabigail")
    if getidleanim ~= nil then
        upvaluehelper.Set(sg.states["idle"].onenter, "getidleanim", newgetidleanim)
    end

    ---------------------------------------------
    
    -- -- 改写阿比盖尔循环攻击 药剂buff生效
    -- local _phase = upvaluehelper.Get(sg.states["gestalt_loop_homing_attack"].onenter, "phase", "stategraphs/SGabigail")
    -- if _phase ~= nil then
    --     print("_phase")
    -- else
    --     print("_phase nil")
    -- end

    ---------------------------------------------
end

AddStategraphPostInit("abigail", SGAbigail)
