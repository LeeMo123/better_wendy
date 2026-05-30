require "behaviours/doaction"
require "behaviours/follow"
require "behaviours/wander"

local GhostBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function IsAlive(target)
    return target.entity:IsVisible() and
        target.components.health ~= nil and
        not target.components.health:IsDead()
end

local TARGET_MUST_TAGS = { "character" }
local TARGET_CANT_TAGS = { "INLIMBO", "noauradamage" }

local function GetFollowTarget(ghost)
    if ghost.brain.followtarget ~= nil
        and (not ghost.brain.followtarget:IsValid() or
            not ghost.brain.followtarget.entity:IsVisible() or
            ghost.brain.followtarget:IsInLimbo() or
            ghost.brain.followtarget.components.health == nil or
            ghost.brain.followtarget.components.health:IsDead() or
            ghost:GetDistanceSqToInst(ghost.brain.followtarget) > TUNING.GHOST_FOLLOW_DSQ)
    then
        ghost.brain.followtarget = nil
    end

    if ghost.brain.followtarget == nil then
        if ghost.components.follower and ghost.components.follower.leader then
            -- print("测试1")
            print(ghost.components.follower.leader)
            ghost.brain.followtarget = ghost.components.follower.leader
        else
            -- print("测试2")
            local gx, gy, gz = ghost.Transform:GetWorldPosition()
            local potential_followtargets = TheSim:FindEntities(gx, gy, gz, 10, TARGET_MUST_TAGS, TARGET_CANT_TAGS)
            for _, pft in ipairs(potential_followtargets) do
                -- We should only follow living characters.
                if IsAlive(pft) then
                    -- If a character is ghost-friendly, don't immediately target them, unless they're targeting us.
                    -- Actively target anybody else.
                    local ghost_friendly = pft:HasTag("ghostlyfriend") or pft:HasTag("abigail")
                    if ghost_friendly then
                        if ghost.components.combat:TargetIs(pft) or (pft.components.combat ~= nil and pft.components.combat:TargetIs(ghost)) then
                            ghost.brain.followtarget = pft
                            break
                        end
                    else
                        ghost.brain.followtarget = pft
                        break
                    end
                end
            end
        end
    end

    return ghost.brain.followtarget
end

local function HasLeader(ghost)
    return ghost.components.follower and ghost.components.follower.leader
end

local function auratest(inst, target, can_initiate)
    -- 1. 自身领袖保护
    if target == inst.components.follower.leader then
        return false  -- 绝对不会攻击自己的领袖
    end

    -- 2. 迷你游戏保护
    if target.components.minigame_participator ~= nil then
        return false  -- 不参与迷你游戏中的实体
    end

    -- 3. 基础免疫判定
    if (target:HasTag("player") and not TheNet:GetPVPEnabled()) -- PVP关闭时保护玩家
       or target:HasTag("ghost") -- 免疫其他鬼魂
       or target:HasTag("noauradamage") then -- 特殊标记免疫
        return false
    end

    -- 4. 队伍关联保护
    local leader = inst.components.follower.leader
    if leader ~= nil and (
        leader == target -- 目标是领袖本人
        or (target.components.follower ~= nil and 
            target.components.follower.leader == leader) -- 目标是同队跟随者
    ) then
        return false  -- 同队单位互不攻击
    end

    -- 5. 主动攻击条件
    if inst.components.combat.target == target then
        return true  -- 如果已经是当前战斗目标
    end

    -- 6. 反击触发条件
    if target.components.combat.target ~= nil and (
        target.components.combat.target == inst or  -- 目标正在攻击自己
        target.components.combat.target == leader   -- 目标正在攻击领袖
    ) then
        return true
    end

    -- 7. 怪物特殊处理
    local ismonster = target:HasTag("monster")
    if ismonster and not TheNet:GetPVPEnabled() and (
        (target.components.follower and 
         target.components.follower.leader ~= nil and 
         target.components.follower.leader:HasTag("player")) -- 被玩家跟随的怪物
        or target.bedazzled -- 被魅惑状态
    ) then
        return false  -- 特殊保护特定怪物
    end

    -- 8. 最终判定
    return not target:HasTag("companion") and ( -- 排除同伴
        can_initiate or  -- 允许主动攻击
        ismonster or     -- 是怪物
        target:HasTag("prey") -- 是猎物
    )
end

local MAX_AGGRESSIVE_FIGHT_DSQ = math.pow(TUNING.ABIGAIL_COMBAT_TARGET_DISTANCE + 2, 2)
local function AggressiveCanFight(inst)

    local target = inst.components.combat.target
    if target ~= nil and not auratest(inst, target) then
        inst.components.combat:GiveUp()
        return false
    end

    if HasLeader(inst) then
        if inst:GetDistanceSqToInst(HasLeader(inst)) < MAX_AGGRESSIVE_FIGHT_DSQ then
            return true
        elseif target ~= nil then
            inst.components.combat:GiveUp()
        end
    end

    return false
end

function GhostBrain:OnStart()
    local root = PriorityNode(
        {
            WhileNode(function() return AggressiveCanFight(self.inst) end, "CanFight",
                ChaseAndAttack(self.inst, TUNING.ABIGAIL_AGGRESSIVE_MAX_CHASE_TIME)
            ),

            WhileNode(function() return GetFollowTarget(self.inst) ~= nil end, "FollowTarget",
                Follow(self.inst, function() return self.inst.brain.followtarget end,
                    HasLeader(self.inst) and 0 or TUNING.GHOST_RADIUS * .25,
                    HasLeader(self.inst) and 5 or TUNING.GHOST_RADIUS * .5,
                    HasLeader(self.inst) and 10 or TUNING.GHOST_RADIUS)
            ),

            -- 无行为时，等待30秒后消失
            SequenceNode {
                ParallelNodeAny {
                    WaitNode(30),
                    Wander(self.inst),
                },
                ActionNode(function() self.inst.sg:GoToState("dissipate") end),
            }
        }, 0.25)

    self.bt = BT(self.inst, root)
end

return GhostBrain