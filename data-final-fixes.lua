function debug_log(text)
  --log(text)
end

-- remove productivity module restrictions, they'll crash the game
for k, v in pairs(data.raw.module) do
  if v.name:find("productivity%-module") then
    v.limitation = nil -- empty limitation table
    v.limitation_message_key = nil
  end
end

local purged_recipes = {}
local known_lowest = {
  "iron-ore", "copper-ore", "coal", "wood", "stone", "iron-plate", "copper-plate", "stone-brick", "plastic-bar", "sulfur", "steel-plate", "uranium-ore"
}
local known_lowest_fluids = {
  "crude-oil", "water", "steam"
}

local known_downgrades = {}
local known_downgrades_fluids = {}

-- some stuff that the script doesn't get well (at least for now)
known_downgrades_fluids["light-oil"] = {{name = "crude-oil", amount = 10, type="fluid"}}
known_downgrades_fluids["heavy-oil"] = {{name = "crude-oil", amount = 10, type="fluid"}}
known_downgrades_fluids["petroleum-gas"] = {{name = "crude-oil", amount = 10, type="fluid"}}

known_downgrades["uranium-238"] = {{name = "uranium-ore", amount = 10}}
known_downgrades["uranium-235"] = {{name = "uranium-ore", amount = 1000}}

 function should_remove_recipe(recipe)
   local items = find_result_items(recipe)
   local keep = false
   if #items == 0 then
     debug_log("no result items for recipe: " .. recipe.name)
    end
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
      local new_item = nil
      new_item = find_item(result)      
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
  if type(name) == "table" then
    if name.name then
      name = name.name
    elseif name[1] then
      name = name[1]
    else
      debug_log(stringify_table(name))
    end
  end
  debug_log("trying to find: " .. name)
  for _, item in pairs(data.raw["item"]) do
    if item.name == name then
      return item
    end
  end
  for _, item in pairs(data.raw["fluid"]) do
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
  if not item then
    debug_log("no item.")
    return false 
  end
  if item.type ~= "item" and item.type ~= "fluid" then 
    debug_log("keeping " .. item.name .. " because of its type :" .. item.type)
    return false 
  end
  if item.place_as_tile then 
    debug_log("keeping " .. item.name .. " as it can be placed as a tile")
    return false
  end
  if item.fuel_value then 
    debug_log("keeping " .. item.name .. " as it has a fuel value")
    return false 
  end
  if item.wire_count then 
    debug_log("keeping " .. item.name .. " as it is a wire")
    return false 
  end
  if item.place_result then 
    debug_log("keeping " .. item.name .. " as it is a placeable entity")
    return false 
  end
  if item.placed_as_equipment_result then 
    debug_log("keeping " .. item.name .. " as it is equipment")
    return false 
  end
  if should_force_keep(item.name) then 
    debug_log("keeping " .. item.name .. " as it is being force-kept")
    return false
  end  
  if item.subgroup == "fluid-recipes" then 
    debug_log("discarding " .. item.name .. " as it is a fluid")
    return true 
  end
  debug_log("discarding " .. item.name .. " because there are no rules left to check.")
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

function find_ingredients(recipe)
  if recipe.ingredients then
    return recipe.ingredients
  end
  if recipe.normal then
    return recipe.normal.ingredients
  end
  if recipe.expensive then
    return recipe.expensive.ingredients
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
  ingredients = ensure_whole_values(ingredients)
  
  return ingredients
end

function ensure_whole_values(ingredients)
  
  local new = {}
  for _, ingredient in ipairs(ingredients) do
    table.insert(new, update_ingredient_amount(ingredient, math.ceil(get_ingredient_amount(ingredient))))
  end
  return new
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

-- move everything that now uses fluids into the crafting-with-fluids category
function maybe_modify_category(recipe)
  if recipe.category and recipe.category ~= "crafting" then
    return
  end
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

-- this is just a simple debug function
function stringify_table(t, depth)
  local fn = function(num) local out = "" local i = 0 while i < num do out = out .. " " i = i + 1 end return out end
  depth = depth or 2
  local out = "{\n"
  for key, value in pairs(t) do
    -- handle key
    out = out .. fn(depth)
    if type(key) == "table" then
      out = out .. "" .. stringify_table(key, depth + 2)
    else
      out = out .. "" .. key
    end
    
    out = out .. " -> "
    
    -- handle value
    if type(value) == "table" then
      out = out .. "" .. stringify_table(value, depth + 2)
    elseif type(value) == "boolean" then
      if value then
        out = out .. "True" 
      else
        out = out .. "False" 
      end
    else
      out = out .. "" .. value
    end
    out = out .. "\n"
  end
  return out .. fn(depth-2) .. "}"
end

function get_recipe_result_count(recipe)
  if recipe.result_count then
    return recipe.result_count
  end
  if recipe.normal and recipe.normal.result_count then
    return recipe.normal.result_count
  end
  return 1
end

-- iterate the recipes, filling the known downgrades with whatever we can
-- (repeated iteration is needed in case an intermediate is defined after an item that uses it)
local handled = {}
for i = 1, 20 do
  for _, recipe in pairs(data.raw["recipe"]) do
    if not handled[recipe] then
      local downgrade = find_downgraded_item(recipe)
      if downgrade ~= "unknown" then
        if get_recipe_result_count(recipe) > 1 then
          local amount = get_recipe_result_count(recipe)
          for k, ingredient in ipairs(downgrade) do
            downgrade[k] = update_ingredient_amount(ingredient, get_ingredient_amount(ingredient) / amount)
          end
        end
        
        known_downgrades[recipe.name] = downgrade
        handled[recipe] = true
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
            debug_log("purging technology: " .. effect.recipe .. " with key " .. i)
            -- get rid of it
            table.remove(tech.effects, i)
            debug_log(stringify_table(tech.effects))
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
 
  -- fix the rocket parts. I guess it either doesn't support fluid or more than 3 parts? Whatever, this works.
  if recipe.name == "rocket-part" then
    table.remove(recipe.ingredients, 4)
    table.remove(recipe.ingredients, 1)
  end
end

-- fix resources that need fluids for mining (ie; uranium ore)
for _, resource in pairs(data.raw["resource"]) do
  if resource.minable then
    if resource.minable.required_fluid then
      resource.minable.required_fluid = 'crude-oil'
    end
  end
end

for _, purged in ipairs(purged_recipes) do
  debug_log("purged recipe: " .. purged)
end