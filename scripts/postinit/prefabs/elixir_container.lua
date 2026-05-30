local containers = require("containers")

-- 野餐盒可以放入料理
containers.params.elixir_container.itemtestfn = function (container, item, slot)
    for i, v in ipairs(GLOBAL.FOODGROUP.OMNI.types) do
        if item:HasAnyTag("spice", "edible_" .. v) then return true end
    end
    return item:HasTag("ghostlyelixir") or item:HasTag("ghostflower") or item:HasTag("preparedfood")
end

-- 格子bg
containers.params.elixir_container.widget.slotbg = {
    { image = "elixir_slot.tex", atlas = "images/hud2.xml" },
    { image = "cook_slot_food.tex"},
    { image = "elixir_slot.tex", atlas = "images/hud2.xml" },
    { image = "cook_slot_food.tex"},
    { image = "elixir_slot.tex", atlas = "images/hud2.xml" },
    { image = "cook_slot_food.tex"},
    { image = "elixir_slot.tex", atlas = "images/hud2.xml" },
    { image = "cook_slot_food.tex"},
    { image = "elixir_slot.tex", atlas = "images/hud2.xml" },
}