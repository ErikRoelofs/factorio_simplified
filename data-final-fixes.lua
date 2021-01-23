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

known_downgrades_fluids["light-oil"] = {{name = "crude-oil", amount = 10, type="fluid"}}
known_downgrades_fluids["heavy-oil"] = {{name = "crude-oil", amount = 10, type="fluid"}}
known_downgrades_fluids["petroleum-gas"] = {{name = "crude-oil", amount = 10, type="fluid"}}

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

function get_ingredient_amount(ingredient)
  local amount = ingredient.amount
  if not amount then
    amount = ingredient[2]
  end
  return amount
end

function update_ingredient_amount(ingredient, new_amount)
  local new_ingredient = table.deepcopy(ingredient)
  if new_ingredient.amount then
    new_ingredient.amount = new_amount
  else
    new_ingredient[2] = new_amount
  end
  
  return new_ingredient
end

function find_downgrade(ingredients)
  local replacements = {}
  local has_gaps = false
  for _, ingredient in pairs(ingredients) do
    local done = false
    local name = get_ingredient_name(ingredient)
    for _, lowest in ipairs(known_lowest) do
      if name == lowest then
        table.insert(replacements, ingredient)
        done = true
      end
    end
    
    if not done then
      for known, downgrades in pairs(known_downgrades) do
        if name == known then
          done = true
          for _, downgrade_ingredient in pairs(downgrades) do
            table.insert(replacements, downgrade_ingredient)
          end
        end
      end
    end
    
    if not done then
      if is_fluid_ingredient(ingredient) then
        done = true
      end
    end
    
    if not done then
      has_gaps = true
    end
  end
  if has_gaps then
    return "unknown"
  else
    return replacements
  end
end

function find_fluid_downgrade(ingredients)  
  local replacements = {}
  local has_gaps = false
  for _, ingredient in pairs(ingredients) do
    local done = false
    local name = get_ingredient_name(ingredient)
    for _, lowest in pairs(known_lowest_fluids) do
      if name == lowest then
        table.insert(replacements, ingredient)
        done = true
      end
    end
    
    if not done then
      for known, downgrades in pairs(known_downgrades_fluids) do
        if name == known then
          for _, downgrade_ingredient in pairs(downgrades) do
            table.insert(replacements, downgrade_ingredient)
          end
        end
      end
    end
    
    if not done then
      if not is_fluid_ingredient(ingredient) then
        done = true
      end
    end
    
    if not done then
      has_gaps = true
    end
  end
  if has_gaps then
    return "unknown"
  else
    return replacements
  end
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
  local new_ingredients = {}
  for key, ingredient in pairs(ingredients) do
    if is_fluid_ingredient(ingredient) then
      local to_add = apply_fluid_downgrade(ingredient)
      if to_add and to_add ~= "unknown" then
        for _, item in pairs(to_add) do
          table.insert(new_ingredients, item)
        end
      end
    else
      local to_add = apply_downgrade(ingredient)
      if to_add and to_add ~= "unknown" then
        for _, item in pairs(to_add) do
          table.insert(new_ingredients, item)
        end
      end
    end
  end
  
  ingredients = merge_ingredients(new_ingredients)
  
  return ingredients
end

-- takes an ingredient; return a table of ingredients to replace it with (might contain duplicates)
function apply_downgrade(ingredient)
  local name = get_ingredient_name(ingredient)
  for _, lowest in ipairs(known_lowest) do
    if name == lowest then
      -- no replacement needed, but response still needs to be a table of ingredients
      return {ingredient}
    end
  end
  for known, replacement in pairs(known_downgrades) do
    if name == known then
      -- build a replacement
      local new_ingredients = {}
      local current_amount = get_ingredient_amount(ingredient)
      for _, replacement_ingredient in pairs(replacement) do
        local new_amount = get_ingredient_amount(replacement_ingredient)      
        table.insert(new_ingredients, update_ingredient_amount(replacement_ingredient, current_amount * new_amount))
      end
      return new_ingredients
    end
  end
end

-- takes an ingredient; return a table of ingredients to replace it with (might contain duplicates)
function apply_fluid_downgrade(ingredient)
  local name = get_ingredient_name(ingredient)
  local done = false
  for _, lowest in ipairs(known_lowest_fluids) do
    if name == lowest then
      -- no replacement needed, but response still needs to be a table of ingredients
      return {ingredient}
    end
  end
  if not done then
    for known, replacement in pairs(known_downgrades_fluids) do
      if name == known then
        return replacement
      end
    end
  end
end

-- merges ingredients without downgrading anything
function merge_ingredients(ingredients)
   
  local instances = {}
  local amounts = {}
  
  -- sum totals per ingredient
  for _, ingredient in pairs(ingredients) do
    local name = get_ingredient_name(ingredient)
    local amount = get_ingredient_amount(ingredient)
    
    if instances[name] then
      amounts[name] = amounts[name] + amount
    else
      instances[name] = ingredient
      amounts[name] = amount
    end
  end
  
  local final_ingredients = {}
  for name, instance in pairs(instances) do
    local new_instance = update_ingredient_amount(instance, amounts[name])
    table.insert(final_ingredients, new_instance)
  end
  
  return final_ingredients
end

function ingredients_contain_fluid(ingredients)
  for _, ingredient in pairs(ingredients) do
    if is_fluid_ingredient(ingredient) then
      return true
    end
  end
  return false
end

function maybe_modify_category(recipe)
  if recipe.ingredients and ingredients_contain_fluid(recipe.ingredients) then
    recipe.category = "crafting-with-fluid"
  end
  if recipe.normal and ingredients_contain_fluid(recipe.normal.ingredients) then
    recipe.category = "crafting-with-fluid"
  end
  if recipe.expensive and ingredients_contain_fluid(recipe.expensive.ingredients) then
    recipe.category = "crafting-with-fluid"
  end
end

function stringify_table(t)
  local out = "{\n"
  for key, value in pairs(t) do
    -- handle key
    if type(key) == "table" then
      out = out .. "key:" .. stringify_table(key)
    else
      out = out .. "key:" .. key
    end
    
    out = out .. " -> \n"
    
    -- handle value
    if type(value) == "table" then
      out = out .. "value:" .. stringify_table(value)
    elseif type(value) == "boolean" then
      if value then
        out = out .. "value: True" 
      else
        out = out .. "value: False" 
      end
    else
      out = out .. "value:" .. value
    end
    out = out .. "\n"
  end
  return out .. "}"
end

-- iterate the recipes, filling the known downgrades with whatever we can
-- (repeated iteration is needed in case an intermediate is defined after an item that uses it)
local handled = {}
for i = 1, 20 do
  for _, recipe in pairs(data.raw["recipe"]) do
    if not handled[recipe] then
      local downgrade = find_downgraded_item(recipe)
      if downgrade ~= "unknown" then
        log( "handled: " .. recipe.name )
        known_downgrades[recipe.name] = downgrade
        handled[recipe] = true
      else
        log( "could not (yet) handle: " .. recipe.name )
      end
    end
  end
end

-- strip out intermediate recipes, downgrade everything else
for recipe_key, recipe in pairs(data.raw["recipe"]) do
  if should_remove_recipe(recipe) then
    table.insert(purged_recipes, recipe_key)
    data.raw["recipe"][recipe_key] = nil
  else
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

for _, recipe in pairs(data.raw["recipe"]) do
  if not recipe.category then
    maybe_modify_category(recipe)
  end
  
  
  if recipe.name == "atomic-bomb" then
    --log(stringify_table(recipe))
    recipe.category = "chemistry"
  end
end
