local AllRecipes = GLOBAL.AllRecipes

-- 墓碑
AddRecipe2("wendy_gravestone",
    { 
        Ingredient("marble", 3), 
        Ingredient("petals_evil", 4) 
    },
    TECH.NONE,
    {
        builder_skill = "wendy_makegravemounds",
        product = "dug_gravestone",
        no_deconstruction = true,
        image = "dug_gravestone.tex",
        description = "wendy_recipe_gravestone"
    }
)

-- 月树花
AddRecipe2("wendy_moon_tree_blossom",
    { 
        Ingredient("petals", 1), 
        Ingredient("ghostflower", 1) 
    },
    TECH.NONE,
    {
        builder_skill = "wendy_sisturn_3",
        product = "moon_tree_blossom",
        no_deconstruction = true,
        image = "moon_tree_blossom.tex",
        description = "wendy_moon_tree_blossom"
    },
    {"CHARACTER"}
)

-- 恶魔花
AddRecipe2("wendy_petals_evil",
    { 
        Ingredient("petals", 1), 
        Ingredient("ghostflower", 1) 
    },
    TECH.NONE,
    {
        builder_skill = "wendy_sisturn_3",
        product = "petals_evil",
        no_deconstruction = true,
        image = "petals_evil.tex",
    },
    {"CHARACTER"}
)

-- Wendy
local function elixir_numtogive(recipe, doer)
	local total = 1
	if doer.components.skilltreeupdater and doer.components.skilltreeupdater:IsActivated("wendy_potion_yield") then
		if math.random() < 0.6 then
			total = 2
        elseif math.random() < 0.1 then
            total = 3
		end	

		if total > 1 then
			doer:PushEvent("craftedextraelixir",total)
		end
	end
	return total
end

-- 定义药剂配方数据表
local elixir_recipes = {
    {   -- 速度药剂
        name = "ghostlyelixir_speed",
        ingredients = {Ingredient("honey", 3), Ingredient("ghostflower", 3)},
    },
    {   -- 防御药剂
        name = "ghostlyelixir_shield",
        ingredients = {Ingredient("log", 3), Ingredient("ghostflower", 3)},
    },
    {   -- 反伤药剂
        name = "ghostlyelixir_retaliation",
        ingredients = {Ingredient("livinglog", 1), Ingredient("ghostflower", 5)},
    },
    {   -- 暗影药剂
        name = "ghostlyelixir_shadow",
        ingredients = {Ingredient("horrorfuel", 3), Ingredient("ghostflower", 5)},
        extra_params = {
            builder_skill = "wendy_shadow_3",
            no_deconstruction = true
        }
    },
    {   -- 月亮药剂
        name = "ghostlyelixir_lunar",
        ingredients = {Ingredient("purebrilliance", 3), Ingredient("ghostflower", 5)},
        extra_params = {
            builder_skill = "wendy_lunar_3",
            no_deconstruction = true
        }
    }
}

-- 循环注册配方并更新
for _, recipe_data in ipairs(elixir_recipes) do
    local params = recipe_data.extra_params or {}
        
    -- 同步更新 AllRecipes 表（确保游戏内其他地方读取配方时也是最新数据）
    if AllRecipes[recipe_data.name] then
        AllRecipes[recipe_data.name].ingredients = recipe_data.ingredients
        -- 如果需要，也可以在这里更新 AllRecipes 的其他属性
        for k, v in pairs(params) do
            AllRecipes[recipe_data.name][k] = v
        end
    end
end