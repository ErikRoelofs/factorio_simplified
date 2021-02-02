data = {
  raw = { },
}
data.extend = function(self, new_tables)
  for _, new_t in pairs(new_tables) do
    if not self.raw[new_t.type] then
      self.raw[new_t.type] = {}
    end
    table.insert(self.raw[new_t.type], new_t)
  end
end

table.deepcopy = function(datatable)
  local tblRes={}
  if type(datatable)=="table" then
    for k,v in pairs(datatable) do tblRes[k]=table.deepcopy(v) end
  else
    tblRes=datatable
  end
  return tblRes
end

util = {
  technology_icon_constant_damage = function() end,
  technology_icon_constant_speed = function() end,
  technology_icon_constant_range = function() end,
  technology_icon_constant_followers = function() end,
  technology_icon_constant_stack_size = function() end,
  technology_icon_constant_capacity = function() end,
  technology_icon_constant_braking_force = function() end,
  technology_icon_constant_movement_speed = function() end,
  technology_icon_constant_equipment = function() end,
  technology_icon_constant_productivity = function() end,
  by_pixel = function() end,
}
sounds = {}

local ensure = function(value, recipe, msg)
  if not value then
    print(msg)
    print(stringify_table(recipe))
  end
end

function validate(recipe, ingredients)
  local recipe_ingredients = find_ingredients(recipe)
  ensure (#recipe_ingredients == #ingredients, recipe, "Number of ingredients mismatch for " .. recipe.name .. " (" .. #ingredients .. " expected, " .. #recipe_ingredients .. " received.")
  for _, expected in ipairs(ingredients) do
    local found = false
    local expected_name = get_ingredient_name(expected)    
    local expected_amount = get_ingredient_amount(expected)
    for _, real in ipairs(recipe_ingredients) do
      local real_name = get_ingredient_name(real)
      if real_name == expected_name then
        real_amount = get_ingredient_amount(real)
        ensure(expected_amount == real_amount, recipe, "Amount of ingredient mismatch for " .. recipe.name .. " on ingredient " .. expected_name .. "(was expecting " .. expected_amount .. ", found " .. real_amount .. ")")
        found = true
      end
    end
    ensure(found, recipe, "Type of ingredient mismatch for " .. recipe.name .. " on ingredient " .. expected_name)
  end  
end