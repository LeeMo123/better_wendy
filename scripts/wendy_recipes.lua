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
    {   -- 小回血药剂
        name = "ghostlyelixir_slowregen",
        ingredients = {Ingredient("spidergland", 1), Ingredient("ghostflower", 3)},
    },
    {   -- 大回血药剂
        name = "ghostlyelixir_fastregen",
        ingredients = {Ingredient("spidergland", 1), Ingredient("ghostflower", 6), Ingredient(CHARACTER_INGREDIENT.HEALTH,30)},
    },
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

for _, recipe_data in ipairs(elixir_recipes) do
    local params = recipe_data.extra_params or {}
        
    -- 同步更新 AllRecipes 表（确保游戏内其他地方读取配方时也是最新数据）
    if AllRecipes[recipe_data.name] then
        local recipe = AllRecipes[recipe_data.name]
        
        -- 清空现有的材料表
        recipe.ingredients = {}
        recipe.character_ingredients = {}
        recipe.tech_ingredients = {}
        
        -- 重新分类并添加所有材料
        for k, v in pairs(recipe_data.ingredients) do
            table.insert(
                (GLOBAL.IsCharacterIngredient(v.type) and recipe.character_ingredients) or
                (GLOBAL.IsTechIngredient(v.type) and recipe.tech_ingredients) or
                recipe.ingredients,
                v
            )
        end
        
        -- 更新其他属性
        for k, v in pairs(params) do
            recipe[k] = v
        end
    end
end