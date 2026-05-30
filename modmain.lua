-- GLOBAL相关照抄
GLOBAL.setmetatable(env, {    __index = function(t, k)        return GLOBAL.rawget(GLOBAL, k)    end})
--

-- 贴图 载入
Assets = {
    -- 技能图标
    Asset("ATLAS", "images/skilltree/wendy_ghostcommand_4.xml"),   -- 作祟技能图标
    Asset("IMAGE", "images/skilltree/wendy_ghostcommand_4.tex"),
    Asset("ATLAS", "images/skilltree/wendy_lunar_1.xml"),
    Asset("IMAGE", "images/skilltree/wendy_lunar_1.tex"),
    Asset("ATLAS", "images/skilltree/wendy_lunar_2.xml"),
    Asset("IMAGE", "images/skilltree/wendy_lunar_2.tex"),
    Asset("ATLAS", "images/skilltree/wendy_shadow_1.xml"),
    Asset("IMAGE", "images/skilltree/wendy_shadow_1.tex"),
    Asset("ATLAS", "images/skilltree/wendy_shadow_2.xml"),
    Asset("IMAGE", "images/skilltree/wendy_shadow_2.tex"),
    -- 
    Asset("ATLAS", "images/skilltree/wendy_background.xml"),   -- 背景图
    Asset("IMAGE", "images/skilltree/wendy_background.tex"),
    -- 
	Asset("ANIM", "anim/abigail_flower_rework.zip"),        -- 阿比盖尔之花
	Asset("ANIM", "anim/wendy_flower_over.zip"),            -- 升级特效
    Asset("ANIM", "anim/ghost_abigail_gestalt_build.zip"),  -- 月灵阿比攻击特效修复
    
}

-- 
modimport("scripts/strings")                                -- 字符相关
modimport("scripts/wendy_recipes")                          -- 配方相关

-- SG动画
modimport("scripts/postinit/SG/SGabigail")                      -- 阿比盖尔的SG动作
-- modimport("scripts/postinit/SG/SGsmallghost")                -- 小惊吓的SG动作
modimport("scripts/postinit/SG/SGwilson")                       -- SG动作  -- 搬重物不掉速

-- prefab
modimport("scripts/postinit/prefabs/sisturn")                   -- 姐妹骨灰盒
modimport("scripts/postinit/prefabs/elixir_container")          -- 野餐盒
modimport("scripts/postinit/prefabs/wendy")                     -- 温蒂
modimport("scripts/postinit/prefabs/graveurn")                  -- 灵魂容器
modimport("scripts/postinit/prefabs/wendy_resurrectiongrave")   -- 温蒂的多年生祭坛
modimport("scripts/postinit/prefabs/ghost")                     -- 鬼魂
modimport("scripts/postinit/prefabs/smallghost")                -- 小惊吓
modimport("scripts/postinit/prefabs/abigail")                   -- 阿比盖尔
modimport("scripts/postinit/prefabs/skilltree_wendy")           -- 温蒂技能树
modimport("scripts/postinit/prefabs/ghostflowerhat")            -- 幽魂花冠
modimport("scripts/postinit/prefabs/ghostcommand")              -- 阿比盖尔 - 指令
modimport("scripts/postinit/prefabs/moondial")                  -- 月晷
modimport("scripts/postinit/prefabs/gravestone")                -- 墓碑  -- 掘墓动作
modimport("scripts/postinit/prefabs/flowers")                   -- 花瓣、深色花瓣、月树花
modimport("scripts/postinit/prefabs/abigail_flower")            -- 阿比盖尔之花
modimport("scripts/postinit/prefabs/ghostly_elixirs")           -- 药剂
modimport("scripts/postinit/prefabs/ghostly_elixirs_buff")      -- 药剂buff

-- 组件
modimport("scripts/postinit/components/sisturnregistry")        -- 姐妹骨灰盒组件
modimport("scripts/postinit/components/locomotor")              -- 移速组件  -- 搬重物不掉速
modimport("scripts/postinit/components/ghostlybond")            -- 鬼魂绑定  -- 修复4级阿比的问题
modimport("scripts/postinit/components/ghostlyelixir")          -- 药剂组件  -- 修复右键直接上药的问题

-- 其他
modimport("scripts/hooks/actions")                          -- 动作
modimport("scripts/tuning")                                 -- 数值

