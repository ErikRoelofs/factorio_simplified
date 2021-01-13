local raenorPower = {
    type = "item",
    name = "raenor-power",
    icon = "__base__/graphics/icons/steam-engine.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "energy",
    order = "b[steam-power]-b[steam-engine]",
    place_result = "raenor-power",
    stack_size = 10
  }
  
data:extend{raenorPower}
  
local recipe =  {
    type = "recipe",
    name = "raenor-power",
    enabled = true,
    normal =
    {
      ingredients =
      {
        {"iron-gear-wheel", 8},
        {"pipe", 5},
        {"iron-plate", 10}
      },
      result = "raenor-power"
    },
}

data:extend{recipe}

--[[
local armor = table.deepcopy(data.raw["recipe"]["heavy-armor"])
armor.enabled = true
armor.name = "fire-armor"
armor.ingredients = {{"copper-plate",200},{"steel-plate",50}}
armor.result = "fire-armor"

data:extend{armor}
]]