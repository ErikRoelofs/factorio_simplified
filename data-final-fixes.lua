-- remove productivity module restrictions, they'll crash the game
for k, v in pairs(data.raw.module) do
  if v.name:find("productivity%-module") then
    v.limitation = nil -- empty limitation table
    v.limitation_message_key = nil
  end
end

local purged_recipes = {}
local known_lowest = {
  "iron-ore", "copper-ore", "coal", "wood", "stone", "iron-plate", "copper-plate", "stone-brick", "plastic-bar", "sulfur", "steel-plate"
}
local known_lowest_fluids = {
  "crude-oil", "water", "steam"
}

local known_downgrades = {}
local known_downgrades_fluids = {}

known_downgrades_fluids["light-oil"] = "crude-oil"
known_downgrades_fluids["heavy-oil"] = "crude-oil"
known_downgrades_fluids["petroleum-gas"] = "crude-oil"

function should_remove_recipe(recipe)
  local items = find_result_items(recipe)
  local keep = false
  for _, item in pairs(items) do
    keep = keep or should_remove_item(item)
  end
  return keep
end

function find_result_items(recipe)
  if recipe.result then
    local new_item = find_item(recipe.result)
    if new_item then
      return {new_item}
    end
    return {}
  end
  if recipe.results then
    local items = {}
    for _, result in pairs(recipe.results) do
      local new_item = find_item(result)
      if new_item then
        table.insert(items, new_item)
      end
    end
    return items
  end
  if recipe.normal.result then
    local new_item = find_item(recipe.normal.result)
    if new_item then
      return {new_item}
    end
    return {}
  end
  if recipe.normal.results then
    local items = {}
    for _, result in pairs(recipe.normal.results) do
      local new_item = find_item(result)
      if new_item then
        table.insert(items, new_item)
      end
    end
    return items
  end
end

function find_item(name)
  for _, item in pairs(data.raw["item"]) do
    if item.name == name then
      return item
    end
  end      
end

function should_force_keep(name)
  for _, keep in ipairs(known_lowest) do
    if name == keep then
      return true
    end
  end
  if name == "rocket-part" then return true end
  return false
end

function should_remove_item(item)  
  if not item then return false end
  if item.place_as_tile then return false end
  if item.fuel_value then return false end
  if item.wire_count then return false end
  if item.place_result then return false end
  if item.placed_as_equipment_result then return false end
  if should_force_keep(item.name) then return false end  
  return true
end

function recipe_output_is_fluid(recipe)
  if recipe.result then
    return false
  end
  if recipe.results then
    for _, item in pairs(recipe.results) do
      if item.type and item.type == "fluid" then
        return true
      end
    end
  end
  return false
end

function find_downgraded_item(recipe)
  local fn = find_downgrade
  if recipe_output_is_fluid(recipe) then
    fn = find_fluid_downgrade
  end
  
  if recipe.ingredients then
    return fn(recipe.ingredients)
  end
  if recipe.normal then
    return fn(recipe.normal.ingredients)
  end
  if recipe.expensive then
    return fn(recipe.expensive.ingredients)
  end
end

function get_ingredient_name(ingredient)
  local name = ingredient.name
  if not name then
    name = ingredient[1]
  end
  return name
end

function update_ingredient_name(ingredient, new_name)
  if ingredient.name then
    ingredient.name = new_name
  else
    ingredient[1] = new_name
  end
end

function find_downgrade(ingredients)
  for _, ingredient in pairs(ingredients) do
    local name = get_ingredient_name(ingredient)
    for _, lowest in ipairs(known_lowest) do
      if name == lowest then
        return lowest
      end
    end
    
    for known, downgrade in ipairs(known_downgrades) do
      if name == known then
        return downgrade
      end
    end
  end
  return "unknown"
end

function find_fluid_downgrade(ingredients)
  for _, ingredient in pairs(ingredients) do
    local name = get_ingredient_name(ingredient)
    for _, lowest in ipairs(known_lowest_fluids) do
      if name == lowest then
        return lowest
      end
    end
    
    for known, downgrade in ipairs(known_downgrades_fluids) do
      if name == known then
        return downgrade
      end
    end
  end
  return "unknown"
end

function do_downgrade_recipe(recipe)
  if recipe.ingredients then
    recipe.ingredients = do_downgrade_ingredients(recipe.ingredients)
  end
  if recipe.normal then
    recipe.normal.ingredients = do_downgrade_ingredients(recipe.normal.ingredients)
  end
  if recipe.expensive then
    recipe.expensive.ingredients = do_downgrade_ingredients(recipe.expensive.ingredients)
  end  
end

function is_fluid_ingredient(ingredient)
  return ingredient.type == "fluid"
end

function do_downgrade_ingredients(ingredients)
  for key, ingredient in pairs(ingredients) do
    if is_fluid_ingredient(ingredient) then
      apply_fluid_downgrade(ingredient)
    else
      apply_downgrade(ingredient)
    end
  end
  local seen = {}
  local len = #ingredients
  for i = len, 1, -1 do
    local ingredient = ingredients[i]
    local name = get_ingredient_name(ingredient)
    
    if seen[name] then
      table.remove(ingredients, i)
    else
      seen[name] = true
    end
  end
  
  return ingredients
end

function apply_downgrade(ingredient)
  local name = get_ingredient_name(ingredient)
  local done = false
  for _, lowest in ipairs(known_lowest) do
    if name == lowest then
      done = true
      break
    end
  end
  if not done then
    for known, replacement in pairs(known_downgrades) do
      if name == known then
        done = true
        update_ingredient_name(ingredient, replacement)
      end
    end
  end
end

function apply_fluid_downgrade(ingredient)
  local name = get_ingredient_name(ingredient)
  local done = false
  for _, lowest in ipairs(known_lowest_fluids) do
    if name == lowest then
      done = true
      break
    end
  end
  if not done then
    for known, replacement in pairs(known_downgrades_fluids) do
      if name == known then
        done = true
        update_ingredient_name(ingredient, replacement)
      end
    end
  end
end


function stringify_table(t)
  local out = ""
  for key, value in pairs(t) do
    if type(key) == "table" then
      out = out .. stringify_table(key)
    else
      out = out .. key
    end
    out = out .. ": "
    if type(value) == "table" then
      out = out .. stringify_table(value)
    else
      out = out .. value
    end
    out = out .. "\n"
  end
  return out
end

-- strip out intermediate recipes
for recipe_key, recipe in pairs(data.raw["recipe"]) do

  if should_remove_recipe(recipe) then
    local downgrade = find_downgraded_item(recipe)
    if downgrade ~= "unknown" then
      known_downgrades[recipe.name] = downgrade
    end

    table.insert(purged_recipes, recipe_key)
    data.raw["recipe"][recipe_key] = nil
  else
    do_downgrade_recipe(recipe)
  end
end

-- make a few additional passes to find all downgraded resource costs for items
for i = 1, 20 do
  for _, recipe in pairs(data.raw["recipe"]) do
      local downgrade = find_downgraded_item(recipe)
      if downgrade ~= "unknown" then
        known_downgrades[recipe.name] = downgrade
      end
      do_downgrade_recipe(recipe)
  end
end

-- strip any removed items from technologies
for _, tech in pairs(data.raw["technology"]) do
  if tech.effects then
    local len = #tech.effects
    for i = len, 1, -1 do
      local effect = tech.effects[i]
      if effect.type == "unlock-recipe" then
        for _, purged in ipairs(purged_recipes) do
          if effect.recipe == purged then
            -- get rid of it
            table.remove(tech.effects, key)
          end
        end
      end
    end
  end
end