local L = locale ~= "zh" and locale ~= "zhr"
name = L and "Better Wendy" or "更好的温蒂"
description = L and
[[
    • Skill Tree Adjustments
]] or [[
    * 技能树调整
    
]]

author = "去码头整点薯条"
version = "2026.06.11"

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

api_version = 10
priority = 1

dont_starve_compatible = true
reign_of_giants_compatible = true
all_clients_require_mod = true
client_only_mod = false
dst_compatible = true

server_filter_tags = { "wendy", "better wendy", "stronger wendy", "温蒂", "更好的温蒂" }