local TUNING = GLOBAL.TUNING

TUNING.SKILLS.WENDY.LUNARELIXIR_DURATION = TUNING.TOTAL_DAY_TIME        -- 月亮阿比时间

TUNING.SKILLS.WENDY.SHADOWELIXIR_DURATION = TUNING.TOTAL_DAY_TIME       -- 暗影阿比时间

TUNING.ABIGAIL_GESTALT_ATTACKAT_DAMAGE_MULT_RATE = 0.9                  -- 冲刺时的伤害递减

TUNING.GHOST_FOLLOW_MIN_DIST = 1.5                                      -- 最小跟随距离
TUNING.GHOST_FOLLOW_TARGET_DIST = 3.0                                   -- 理想跟随距离
TUNING.GHOST_FOLLOW_MAX_DIST = 6.0                                      -- 最大跟随距离
TUNING.GHOST_FOLLOW_DSQ = 20 * 20                                       -- 失联距离平方

-- 温蒂指令冷却时间
TUNING.WENDY_COMMAND_COOLDOWN = {
    do_ghost_escape = 30,           -- 逃离
    do_ghost_attackat = 15,         -- 攻击
    scare = 20,                     -- 惊吓
    do_ghost_hauntat = 1.25,         -- 作祟
}

-- 四级生命值
TUNING.ABIGAIL_HEALTH_LEVEL4 = 900

-- 光圈亮度
TUNING.ABIGAIL_LIGHTING =
{
    {l = 0.0, r = 0.0},
    {l = 0.1, r = 0.3, i = 0.7, f = 0.5},
    {l = 0.5, r = 0.7, i = 0.6, f = 0.6},
    {l = 0.5, r = 0.7, i = 0.6, f = 0.6},
}

-- 不同时间段的额外生命值变化
TUNING.WENDY_BONUS_HEALTH = {
    LEVEL1 = TUNING.ABIGAIL_HEALTH_LEVEL1,
    LEVEL2 = TUNING.ABIGAIL_HEALTH_LEVEL2,
    LEVEL3 = TUNING.ABIGAIL_HEALTH_LEVEL3,
    LEVEL4 = TUNING.ABIGAIL_HEALTH_LEVEL4, -- 技能树第四级
}

-- Wendy Skill Tree
TUNING.ABIGAIL_GESTALT_DAMAGE =
{
    day = 100,
    dusk = 150,
    night = 200,
}

-- 蒸馏药剂反伤  -- 伤害
TUNING.GHOSTLYELIXIR_RETALIATION_DAMAGE = 47

-- 药剂持续时间
-- 对于玩家
TUNING.GHOSTLYELIXIR_PLAYER_DAMAGE_DURATION = 60*5 -- 5分钟  -- 夜影万金油 
TUNING.GHOSTLYELIXIR_PLAYER_SPEED_DURATION  = 60*5 -- 5分钟  -- 强健精油  
TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_DURATION = 60*5 -- 5分钟  -- 不屈药剂
TUNING.GHOSTLYELIXIR_PLAYER_SHIELD_DURATION = 60*5 -- 5分钟  -- 复仇药剂
-- 对于阿比


TUNING.GHOSTLYELIXIR_SLOWREGEN_DURATION = TUNING.TOTAL_DAY_TIME/2.5 -- 小药剂回血 每秒回复5滴血 持续192秒
TUNING.GHOSTLYELIXIR_SLOWREGEN_HEALING = 5

TUNING.WENDY_CHANGE = {
    GHOSTEXPLODE1_MIN_DAMAGE = 168,      -- 鬼魂最小爆炸伤害
    GHOSTEXPLODE1_MAX_DAMAGE = 222,      -- 鬼魂最大爆炸伤害

    DAMAGEMULTIPLIER_DAY = 0.75,        -- 白天伤害
    DAMAGEMULTIPLIER_DUSK = 0.9,        -- 黄昏伤害
    DAMAGEMULTIPLIER_NIGHT = 1,         -- 夜间伤害
}