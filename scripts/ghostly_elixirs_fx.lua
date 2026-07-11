local GLOBAL = _G

local function FinalOffset3(inst)
    inst.AnimState:SetFinalOffset(3)
end

local fx = {
    {
        name = "ghostlyelixir_light_fx",
        bank = "more_abigail_vial_fx",
        build = "more_abigail_vial_fx",
        anim = "buff_light",
        sound = "dontstarve/characters/wendy/abigail/buff/retaliation",
        fn = FinalOffset3,
    },
    {
        name = "ghostlyelixir_light_dripfx",
        bank = "abigail_buff_drip",
        build = "more_abigail_vial_fx",
        anim = "abigail_buff_drip",
        fn = function(inst)
	        inst.AnimState:OverrideSymbol("fx_swap", "more_abigail_vial_fx", "fx_light_02")
		    inst.AnimState:SetFinalOffset(3)
		end,
    },
    {
        name = "ghostlyelixir_player_light_fx",
        bank = "more_player_vial_fx",
        build = "more_player_vial_fx",
        anim = "buff_light",
        sound = "dontstarve/characters/wendy/abigail/buff/retaliation",
        fn = FinalOffset3,
    },
    {
        name = "ghostlyelixir_player_light_dripfx",
        bank = "player_elixir_buff_drip",
        build = "more_player_vial_fx",
        anim = "player_elixir_buff_drip",
        fn = function(inst)
            inst.AnimState:OverrideSymbol("fx_swap", "more_player_vial_fx", "fx_light_02")
            inst.AnimState:SetFinalOffset(3)
        end,
    },
}

for k, v in ipairs(fx) do
    GLOBAL.table.insert(GLOBAL.require("fx"), v)
end


