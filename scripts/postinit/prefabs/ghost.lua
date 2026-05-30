local brain = require "brains/ghostbrain"
local AURA_EXCLUDE_TAGS = { "playerghost", "abigail", "ghost", "shadow", "INLIMBO", "notarget", "noattack", "invisible", "wall", "player" }

-- 召唤鬼魂
local function OnSummons(inst, leader)
    -- 跟踪组件
    local follower = inst.components.follower
    follower:SetLeader(leader) -- 替换StartFollowing

    -- 移动组件
    local locomotor = inst.components.locomotor
    locomotor.walkspeed = TUNING.ABIGAIL_SPEED / 2
    locomotor.runspeed = 4

    -- 碰撞体积
    local physics = inst.Physics
    physics:SetCapsule(0, 0)

    -- 死亡后爆炸
    local wendy_avenging_ghost = leader and leader.components.skilltreeupdater and
                    leader.components.skilltreeupdater:IsActivated("wendy_avenging_ghost") and math.random(1.5, 2) or 1

    inst.explode = true
    inst:ListenForEvent("death", function ()
        if not inst.explode then
            return
        end
    
        local random_damage = math.random(TUNING.WENDY_CHANGE.GHOSTEXPLODE1_MIN_DAMAGE, TUNING.WENDY_CHANGE.GHOSTEXPLODE1_MAX_DAMAGE)
        local x, y, z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, y, z, 3, {"_combat", "_health"}, AURA_EXCLUDE_TAGS)
        for _, v in pairs(ents) do
            if v ~= inst and v.entity:IsVisible() then
                v.components.combat:GetAttacked(inst, random_damage * wendy_avenging_ghost, nil)
                v:PushEvent("explosion", { explosive = inst })
            end
        end
    
        -- 爆炸特效
        SpawnPrefab("explode_small_slurtle").Transform:SetPosition(x, y, z)
    end)
end

-- 召回鬼魂
local function OnDismiss(inst)
    inst.explode = false
    -- 移除鬼魂
    inst.components.health:Kill()
end

local ghosts = { "ghost", "graveguard_ghost" }

for _, ghost_name in pairs(ghosts) do
    AddPrefabPostInit(ghost_name, function(inst)
        if not TheWorld.ismastersim then
            return inst
        end

        -- 跟随
        local follower = inst:AddComponent("follower")
        follower:KeepLeaderOnAttacked()
        follower.keepdeadleader = true
        follower.keepleaderduringminigame = true

        -- brain
        if ghost_name == "ghost" then
            inst:SetBrain(brain)
        end

        -- 血量组件
        local health = inst.components.health
        health:StartRegen(1, 3)

        -- 
        inst.OnDismiss = OnDismiss

        if ghost_name == "graveguard_ghost" then
            return
        end

        -- 初始化一下参数
        inst.explode = false

        inst.OnSummons = OnSummons
        inst.ExplodeFeather = ExplodeFeather

        local OldOnSave = inst.OnSave
        inst.OnSave = function(inst, data)
            data.explode = inst.explode

            if OldOnSave then
                OldOnSave(inst, data)
            end
        end

        local OldOnLoad = inst.OnLoad
        inst.OnLoad = function(inst, data)
            inst.explode = data.explode
            if inst.explode then
                -- 加个延时,重新载入时技能树总是慢几秒才能触发，服了，Klei什么时候修
                inst:DoTaskInTime(3, function()
                    OnSummons(inst, inst.components.follower.leader)
                end)
            end

            if OldOnLoad then
                OldOnLoad(inst, data)
            end
        end
    end)    
end