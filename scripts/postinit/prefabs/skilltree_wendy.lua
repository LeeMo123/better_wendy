local WENDY_SKILL_STRINGS = STRINGS.SKILLTREE.WENDY
local SkillTreeDefs = require("prefabs/skilltree_defs")

-- Positions
local TILEGAP = 38
local TILE = 50
local POS_X_1 = -245 -- -211
local POS_Y_1 = 172

local X = -298
local Y = 288

local width = 255 + 249 - 50
local height = 142 + 10

local CURVE_BASE_H = 75
local A_BASE_H = -10 + TILE

local COL1 = POS_X_1 + math.floor(width / 11)
local COL2 = POS_X_1 + math.floor(width / 11) * 2
local COL3 = POS_X_1 + math.floor(width / 11) * 3
local COL4 = POS_X_1 + math.floor(width / 11) * 4
local COL5 = POS_X_1 + math.floor(width / 11) * 5

local COL6 = POS_X_1 + math.floor(width / 11) * 7
local COL7 = POS_X_1 + math.floor(width / 11) * 8
local COL8 = POS_X_1 + math.floor(width / 11) * 9
local COL9 = POS_X_1 + math.floor(width / 11) * 10
local COL10 = POS_X_1 + math.floor(width / 11) * 11

local CURV1 = CURVE_BASE_H + 0
local CURV2 = CURVE_BASE_H + math.floor(TILE / 1.5)
local CURV3 = CURVE_BASE_H + math.floor(TILE / 1.5 + TILE / 3)
local CURV4 = CURVE_BASE_H + math.floor(TILE / 1.5 + TILE / 3 + TILE / 4)
local CURV5 = CURVE_BASE_H + math.floor(TILE / 1.5 + TILE / 3 + TILE / 4 + TILE / 5)

--

local function goinsane(inst)
    local abigail = inst.components.ghostlybond.ghost
    abigail:_sanitychange(true)
end

local function gosane(inst)
    local abigail = inst.components.ghostlybond.ghost
    abigail:_sanitychange(false)
end

local function UpdateDamage(inst)
    local phase = TheWorld.state.phase
    local isactivated = inst.components.skilltreeupdater:IsActivated("wendy_shadow_2") and 0.1 or 0

    inst.components.combat.damagemultiplier = isactivated + 
                            ((phase == "dusk" and TUNING.WENDY_CHANGE.DAMAGEMULTIPLIER_DUSK) or
                            (phase == "night" and TUNING.WENDY_CHANGE.DAMAGEMULTIPLIER_NIGHT) or
                            TUNING.WENDY_CHANGE.DAMAGEMULTIPLIER_DAY)
end

-- 

local skills = {}
local function finalize_skill_group(skill_subset, group_name)
    for skill_name, skill_data in pairs(skill_subset) do
        local skill_name_upper = string.upper(skill_name)
        skill_data.group = group_name
        table.insert(skill_data.tags, group_name)

        skill_data.desc = skill_data.desc or WENDY_SKILL_STRINGS[skill_name_upper .. "_DESC"]
        if not skill_data.lock_open then
            skill_data.title = skill_data.title or WENDY_SKILL_STRINGS[skill_name_upper .. "_TITLE"]
            skill_data.icon = skill_data.icon or skill_name
        end

        skills[skill_name] = skill_data
    end
end

local sisturn_skills = {
    wendy_sisturn_1 = {
        pos = {103, 173}, -- {-193-5,102-2},
        tags = {"sisturn"},
        root = true,
        connects = {"wendy_sisturn_2"},
        defaultfocus = true
    },
    wendy_sisturn_2 = {
        pos = {140, 154}, -- {COL2-2-8, CURV2+ TILEGAP -10},
        tags = {"sisturn"},
        onactivate = function(inst, fromload)
            inst.components.sanityauraadjuster:StartTask()
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond:SetMaxBondLevel(4)
            end
        end,
        
        ondeactivate = function(inst, fromload)
            inst.components.sanityauraadjuster:StopTask()
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                if inst.components.ghostlybond.bondlevel > 3 then
                    inst.components.ghostlybond:SetBondLevel(3)
                end
                inst.components.ghostlybond:SetMaxBondLevel(3)
            end
        end,
        connects = {"wendy_sisturn_3"}
    },

    wendy_sisturn_3 = {
        pos = {176, 133}, -- {COL3-4-10, CURV3+ TILEGAP-3},
        tags = {"sisturn"},
        onactivate = function(inst, fromload)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:updatehealingbuffs()
            end
        end,
        ondeactivate = function(inst, fromload)

            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:updatehealingbuffs()
            end
        end
    }
}
finalize_skill_group(sisturn_skills, "sisturn_upgrades")

local potion_skills = {
    wendy_potion_container = {
        pos = {COL4 + 10 + 14, CURV5 + TILEGAP}, -- {COL1+35, CURV1-16},
        tags = {"potion"},
        root = true,

        onactivate = function(inst, fromload)
            inst:AddTag("elixircontaineruser")
        end,

        ondeactivate = function(inst, fromload)
            inst:RemoveTag("elixircontaineruser")
        end
    },

    wendy_potion_duration = {
        pos =  {COL4+10+13+TILEGAP,190}, --{X+ 152,Y-192},
        tags = {"potion"},
        root = true,

        connects = {"wendy_potion_yield"}
    },
    wendy_potion_yield = {
        pos =  {COL4+10+12+TILEGAP+TILEGAP+1,190}, --{X+ 190, Y-170},
        tags = {"potion"},
        connects = {"wendy_potion_revive"}
    },
    wendy_potion_revive = {
        pos =  {COL6+11+4, CURV5+TILEGAP}, -- {COL4+11, Y-154},
        tags = {"potion"},
    },
}
finalize_skill_group(potion_skills, "potion_upgrades")

local smallghost_skills = {
    wendy_smallghost_1 = {
        pos = {-173, 133}, -- {COL6+11+6, CURV5+TILEGAP},
        tags = {},
        root = true,
        connects = {"wendy_smallghost_2"}
    },
    wendy_smallghost_2 = {
        pos = {-138, 154}, -- {X+390+6,Y-115},
        tags = {},
        connects = {"wendy_smallghost_3"}
    },
    wendy_smallghost_3 = {
        pos = {-101, 173}, -- {X+428+6,Y-137},
        tags = {}
    }
}
finalize_skill_group(smallghost_skills, "smallghost")

local ghostflower_skills = {
    wendy_ghostflower_hat = {
        title = STRINGS.SKILLTREE.WENDY.WENDY_GHOSTFLOWER_BUTTERFLY_TITLE,
        pos = {-47 + 18, CURV5 - 5},
        tags = {},
        root = true,
        connects = {"wendy_ghostflower_grave"}
    },
    wendy_ghostflower_grave = {
        title = STRINGS.SKILLTREE.WENDY.WENDY_GHOSTFLOWER_HAT_TITLE,
        pos = {-47 + 60 , CURV5 - 4 },
        tags = {}
    }
}
finalize_skill_group(ghostflower_skills, "ghostflower")

local gravestone_skills = {
    wendy_gravestone_1 = {
        pos = {-168, 73}, --{COL4+10+14,CURV5+TILEGAP},
        tags = {},
        root = true,

        onactivate = function(inst, fromload)
            inst:AddTag(UPGRADETYPES.GRAVESTONE .. "_upgradeuser")
            inst:AddTag("gravedigger_user")
        end,

        ondeactivate = function(inst, fromload)
            inst:RemoveTag(UPGRADETYPES.GRAVESTONE .. "_upgradeuser")
            inst:RemoveTag("gravedigger_user")
        end,

        connects = {"wendy_makegravemounds"}
    },

    wendy_makegravemounds = {
        pos = {-132,100},-- {COL4+10+13+TILEGAP,CURV5+TILEGAP+5},
        tags = {},
        
        connects = {"wendy_avenging_ghost"}
    },

    wendy_avenging_ghost = {
        title = STRINGS.SKILLTREE.WENDY.WENDY_AVENGING_GHOST_TITLE,
        desc = STRINGS.SKILLTREE.WENDY.WENDY_AVENGING_GHOST_DESC,
        icon = "wendy_avenging_ghost",
        pos =  {-96, 118},  --{COL4+10+12+TILEGAP+TILEGAP,CURV5+TILEGAP+ 6},
        tags = {},
    },

}
finalize_skill_group(gravestone_skills, "gravestone")

local ghost_command_skills = {
    wendy_ghostcommand_1 = {
        pos = {62, 136},
        tags = {},
        -- connects = {"wendy_ghostcommand_2"},

        root = true
    },
    wendy_ghostcommand_2 = {
        pos = {98, 118}, -- {X+482-5,Y-175+15},
        tags = {},
        -- connects = {"wendy_ghostcommand_3"}
        
        root = true
    },
    wendy_ghostcommand_3 = {
        pos = {135, 100},
        tags = {},

        root = true
    },
    wendy_ghostcommand_4 = {
        pos = {171, 73},
        tags = {},

        root = true
    }
}
finalize_skill_group(ghost_command_skills, "ghost_command")

local allegiance_skills = {

    wendy_shadow_lock_1 = SkillTreeDefs.FN.MakeNoLunarLock({
        pos = {COL3 + TILEGAP / 2 + 14, A_BASE_H - 3}
    }),

    wendy_shadow_1 = {
        pos = {COL4+TILEGAP/2 +11, A_BASE_H - 3},
        tags = {"allegiance", "shadow", "shadow_favor"},
        locks = {"wendy_shadow_lock_1", "wendy_shadow_lock_2"},

        connects = {"wendy_shadow_2"},

        onactivate = function(inst, fromload)
            inst:AddTag("player_shadow_aligned")

            -- 位面实体抵抗
            if inst.components.ghostlybond.ghost.components.planarentity == nil then
                inst.components.ghostlybond.ghost:AddComponent("planarentity")            
            end

            local addresists = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("shadow_aligned", pref, 0.9, "allegiance_shadow")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("lunar_aligned", pref, 1.1, "allegiance_shadow")
                end
            end

            addresists(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:AddTag("shadow_aligned")
                addresists(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(8)
            end
            
            inst:WatchWorldState("phase", UpdateDamage)
            UpdateDamage(inst)
        end,

        ondeactivate = function(inst, fromload)
            inst:RemoveTag("player_shadow_aligned")

            -- 移除位面实体抵抗
            if inst.components.ghostlybond.ghost.components.planarentity ~= nil then
                inst.components.ghostlybond.ghost:RemoveComponent("planarentity")
            end

            local removeresist = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("shadow_aligned", pref, "allegiance_shadow")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("lunar_aligned", pref, "allegiance_shadow")
                end
            end
            removeresist(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:RemoveTag("shadow_aligned")
                removeresist(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(0)
            end
            
            inst:StopWatchingWorldState("phase", UpdateDamage)
            inst.components.combat.damagemultiplier = 0.75
        end
    },

    wendy_shadow_2 = {
        pos = {COL4+TILEGAP/2 + 50, A_BASE_H - 3},
        tags = {"allegiance", "shadow", "shadow_favor"},        

        onactivate = function(inst, fromload)
            inst:AddTag("player_shadow_aligned")

            local addresists = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("shadow_aligned", pref, 0.8, "allegiance_shadow")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("lunar_aligned", pref, 1.2, "allegiance_shadow")
                end
            end

            addresists(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:AddTag("shadow_aligned")
                addresists(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(15)
            end
        end,

        ondeactivate = function(inst, fromload)
            inst:RemoveTag("player_shadow_aligned")

            local removeresist = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("shadow_aligned", pref, "allegiance_shadow")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("lunar_aligned", pref, "allegiance_shadow")
                end
            end
            removeresist(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:RemoveTag("shadow_aligned")
                removeresist(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(0)
            end
        end
    },

    wendy_shadow_lock_2 = SkillTreeDefs.FN.MakeFuelWeaverLock({
        pos = {COL5 + (width / 11) + TILEGAP / 2 + 12, A_BASE_H - 3},   -- new
    }),

    wendy_shadow_3 = {
        locks = { "wendy_shadow_lock_2"},
        pos = {COL6+TILEGAP/2 +12, A_BASE_H - 3},               -- new
        tags = { },
    },

    wendy_lunar_lock_1 = SkillTreeDefs.FN.MakeNoShadowLock({
        pos = {COL3 + TILEGAP / 2 + 14, A_BASE_H + TILEGAP - 3}
    }),

    wendy_lunar_1 = {
        pos = {COL4+TILEGAP/2 +11, A_BASE_H+TILEGAP - 3},                           -- new
        tags = {"allegiance", "lunar", "lunar_favor"},
        connects = {"wendy_lunar_2"},

        locks = {"wendy_lunar_lock_1", "wendy_lunar_lock_2"},

        onactivate = function(inst, fromload)
            inst:AddTag("player_lunar_aligned")

            -- 位面实体抵抗
            if inst.components.ghostlybond.ghost.components.planarentity == nil then
                inst.components.ghostlybond.ghost:AddComponent("planarentity")            
            end
            
            local addresists = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("lunar_aligned", pref, 0.9, "allegiance_lunar")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("shadow_aligned", pref, 1.1, "allegiance_lunar")
                end
            end

            addresists(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:AddTag("lunar_aligned")
                addresists(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(8)
            end

            -- inst:ListenForEvent("goinsane", goinsane)
            -- inst:ListenForEvent("gosane", gosane)
        end,

        ondeactivate = function(inst, fromload)
            inst:RemoveTag("player_lunar_aligned")

            -- 移除位面实体抵抗
            if inst.components.ghostlybond.ghost.components.planarentity ~= nil then
                inst.components.ghostlybond.ghost:RemoveComponent("planarentity")
            end

            local removeresist = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("lunar_aligned", pref, "allegiance_lunar")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("shadow_aligned", pref, "allegiance_lunar")
                end
            end
            removeresist(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:RemoveTag("lunar_aligned")
                removeresist(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(0)
            end

            -- inst:RemoveEventCallback("goinsane", goinsane)
            -- inst:RemoveEventCallback("gosane", gosane)
        end
    },

    wendy_lunar_2 = {
        pos = {COL4+TILEGAP/2 + 50, A_BASE_H+TILEGAP - 3},
        tags = {"allegiance", "lunar", "lunar_favor"},

        onactivate = function(inst, fromload)
            inst:AddTag("player_lunar_aligned")

            local   addresists = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:AddResist("lunar_aligned", pref, 0.8, "allegiance_lunar")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:AddBonus("shadow_aligned", pref, 1.2,"allegiance_lunar")
                end
            end

            addresists(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:AddTag("lunar_aligned")
                addresists(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(15)
            end
        end,

        ondeactivate = function(inst, fromload)
            inst:RemoveTag("player_lunar_aligned")

            local removeresist = function(pref)
                local damagetyperesist = pref.components.damagetyperesist
                if damagetyperesist then
                    damagetyperesist:RemoveResist("lunar_aligned", pref, "allegiance_lunar")
                end
                local damagetypebonus = pref.components.damagetypebonus
                if damagetypebonus then
                    damagetypebonus:RemoveBonus("shadow_aligned", pref, "allegiance_lunar")
                end
            end
            removeresist(inst)
            if inst.components.ghostlybond and inst.components.ghostlybond.ghost then
                inst.components.ghostlybond.ghost:RemoveTag("lunar_aligned")
                removeresist(inst.components.ghostlybond.ghost)
                inst.components.ghostlybond.ghost.components.planardefense:SetBaseDefense(0)
            end
        end
    },
    
    wendy_lunar_lock_2 = SkillTreeDefs.FN.MakeCelestialChampionLock({
        pos = {COL5+(width/11)+TILEGAP/2 +12, A_BASE_H+TILEGAP - 3},-- new
    }),

    wendy_lunar_3 = {
        pos = {COL6+TILEGAP/2 +12, A_BASE_H+TILEGAP - 3},           -- new
        locks = {"wendy_lunar_lock_2" },
        tags = { }
    },

}
finalize_skill_group(allegiance_skills, "wendy_alliegience") -- allegiance

-- Create skill tree
if SkillTreeDefs.SKILLTREE_DEFS["wendy"] ~= nil then -- in case another mod turns it nil beforehand (disabling skill tree)
    SkillTreeDefs.SKILLTREE_DEFS["wendy"] = {}
    SkillTreeDefs.CreateSkillTreeFor("wendy", skills)
end

-- 技能树 技能图标
local OldGetSkilltreeIconAtlas = GLOBAL.GetSkilltreeIconAtlas
function GLOBAL.GetSkilltreeIconAtlas(imagename, ...)
    if imagename == "wendy_ghostcommand_4.tex" then
        return "images/skilltree/wendy_ghostcommand_4.xml"
    elseif imagename == "wendy_lunar_1.tex" then
        return "images/skilltree/wendy_lunar_1.xml"
    elseif imagename == "wendy_lunar_2.tex" then
        return "images/skilltree/wendy_lunar_2.xml"
    elseif imagename == "wendy_shadow_1.tex" then
        return "images/skilltree/wendy_shadow_1.xml"
    elseif imagename == "wendy_shadow_2.tex" then
        return "images/skilltree/wendy_shadow_2.xml"
        
    -- 其他的
    else
        return OldGetSkilltreeIconAtlas(imagename, ...)
    end
end

-- 技能树 背景图
local OldGetSkilltreeBG = GLOBAL.GetSkilltreeBG
function GLOBAL.GetSkilltreeBG(imagename, ...)
    if imagename == "wendy_background.tex"then
        return "images/skilltree/wendy_background.xml"
    else
        return OldGetSkilltreeBG(imagename, ...)
    end
end