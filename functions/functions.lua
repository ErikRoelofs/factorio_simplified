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

function find_item(name, item_type)
  if type(name) == "table" then
    if name.name then
      name = name.name
    elseif name[1] then
      name = name[1]
    else
      debug_log(stringify_table(name))
    end
  end
  -- if we know the type, check it first
  if item_type then
    for _, item in pairs(data.raw[item_type]) do
      if item.name == name then
        return item
      end
    end
  end
  
  -- search all known locations of items
  local search_tables = {"item", "fluid", "armor", "gun", "item-with-entity-data", "ammo", "capsule", "item-with-inventory", "tool", "item-with-label", "mining-tool", "upgrade-item", "repair-tool", "module", "spidertron-remote"}
  for _, subtable in ipairs(search_tables) do
    for _, item in pairs(data.raw[subtable]) do
      if item.name == name then
        return item
      end
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
  if name == "satellite" then return true end
  return false
end

function is_intermediate(item)
  if not item then
    return false
  end
  if item.type ~= "item" and item.type ~= "fluid" then 
    return false
  end
  if item.place_as_tile then 
    return false
  end
  if item.fuel_value then 
    return false 
  end
  if item.wire_count then 
    return false 
  end
  if item.place_result then 
    return false 
  end
  if item.placed_as_equipment_result then 
    return false 
  end
  if item.subgroup == "fluid-recipes" then 
    return true 
  end
  return true
end

function should_remove_item(item)  
  return is_intermediate(item) and not should_force_keep(item.name)
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
  debug_log(stringify_table(recipe))
  error("Could not find ingredients.")
end

function replace_recipe_ingredients(recipe, new_ingredients)
  if recipe.ingredients then
    recipe.ingredients = new_ingredients
  end
  if recipe.normal then
    recipe.normal.ingredients = new_ingredients
  end
  if recipe.expensive then
    recipe.expensive.ingredients = new_ingredients
  end  
end

function is_fluid_ingredient(ingredient)
  return ingredient.type == "fluid"
end

function ensure_whole_values(ingredients)
  
  local new = {}
  for _, ingredient in ipairs(ingredients) do
    table.insert(new, update_ingredient_amount(ingredient, math.ceil(get_ingredient_amount(ingredient))))
  end
  return new
end

-- merges ingredients without downgrading anything
function merge_ingredients(ingredients)
   
  local instances = {}
  local amounts = {}
  
  -- sum totals per ingredient
  for _, ingredient in pairs(ingredients) do
    local name = get_ingredient_name(ingredient)
    local amount = get_ingredient_amount(ingredient)
    assert(name, "This does not look like ingredients: " .. stringify_table(ingredients))
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

function get_recipe_result_count(recipe, item_name)
  if recipe.result_count then
    return recipe.result_count
  end
  if recipe.normal and recipe.normal.result_count then
    return recipe.normal.result_count
  end
  if recipe.results and item_name then
    for _, result in ipairs(recipe.results) do
      if get_ingredient_name(result) == item_name then
        if result.probability then
          return result.probability * result.amount
        else
          return get_ingredient_amount(result)
        end
      end
    end
  end
  return 1
end

function get_recipe_result_num_items(recipe)
  if recipe.result_count then
    return 1
  end
  if recipe.normal and recipe.normal.result_count then
    return 1
  end
  if recipe.results then
    return #recipe.results
  end
  return 1
end


function determine_tier(ingredients, result_item)
  local max_tier = 0
  for _, ingredient in pairs(ingredients) do
    local name = get_ingredient_name(ingredient)
    local tier = ingredient_tier[name]
    if tier == nil then return nil end
    max_tier = math.max(tier, max_tier)
  end
  if is_intermediate(result_item) then
    return max_tier + 1
  end
  return max_tier
end

function multiply_ingredient_cost(ingredients, multiplier)
  local multiplied = {}
  for _, ingredient in ipairs(ingredients) do
    table.insert(multiplied, update_ingredient_amount(ingredient, get_ingredient_amount(ingredient) * multiplier))
  end  
  return multiplied  
end


function crop_ingredients(ingredients)
  -- for now, just crop out multiple fluids
  local highest_fluid_count = 0
  local highest_fluid_name = nil
  for _, i in ipairs(ingredients) do
    if is_fluid_ingredient(i) then
      if get_ingredient_amount(i) > highest_fluid_count then
        highest_fluid_name = get_ingredient_name(i)
      end
    end
  end
  
  if highest_fluid_name then
    for i = #ingredients, 1, -1 do
      if is_fluid_ingredient(ingredients[i]) then
        if get_ingredient_name(ingredients[i]) ~= highest_fluid_name then
          table.remove(ingredients, i)
        end
      end
    end
  end
  
  return ingredients
end

-- new stuff

function determine_new_recipe_cost(recipe, other_known_item_costs, max_tier, max_num_ingredients)
  local results = find_result_items(recipe)
  local total_cost = {}
  
  for _, result in ipairs(results) do
    
    local result_item = result.name
    local ingredients = find_ingredients(recipe)
    local new_ingredients = determine_new_item_costs(result_item, other_known_item_costs)
    debug_log("new ingredients for " .. result_item .. ": " .. stringify_table(new_ingredients))
    
    -- multiply for the current count
    local count = get_recipe_result_count(recipe, result_item)
    local ingredients = multiply_ingredient_cost(new_ingredients, count)
    
    for _, i in ipairs(ingredients) do
      table.insert(total_cost, i)
    end
  end
    
  -- merge
  total_cost = merge_ingredients(total_cost)
  total_cost = ensure_whole_values(total_cost)
  
  -- crop it
  total_cost = crop_ingredients(total_cost)
  
  
  return total_cost
end

function determine_new_item_costs(item_name, other_known_item_costs)
  -- cache
  if other_known_item_costs[item_name] then return other_known_item_costs[item_name] end
  
  local max_tier = 0
  if item_is_intermediate[item_name] and ingredient_tier[item_name] <= max_tier then
    -- this need not be downgraded
    return {{item_name, 1}}
  end  
  
  debug_log("determining item costs for: " .. item_name)
  assert(item_name, "No item name given.")
  -- find the recipe(s) that make this
  local recipe = find_recipe_for(item_name)
  if not recipe then
    -- there is no recipe; this must be mined directly
    -- this is directly manipulating the script's storage tables.
    table.insert(known_lowest, item_name)
    ingredient_tier[item_name] = 0
    item_is_intermediate[item_name] = is_intermediate(item)
    -- this item costs 1 of itself, cache it
    other_known_item_costs[item_name] = {{item_name, 1}}
    return other_known_item_costs[item_name]
  end
  
  local current_ingredients = find_ingredients(recipe)
  local new_ingredients = {}
  
  for _, ingredient in ipairs(current_ingredients) do
    local ingredient_name = get_ingredient_name(ingredient)
    local ingredient_amount = get_ingredient_amount(ingredient)
    
    if item_is_intermediate[ingredient_name] and ingredient_tier[ingredient_name] <= max_tier then
      -- keep this ingredient
      table.insert(new_ingredients, ingredient)
    else
      -- downgrade this ingredient
      debug_log("downgrading: " .. ingredient_name .. " (amount: " .. ingredient_amount .. ")")
      local costs = determine_new_item_costs(ingredient_name, other_known_item_costs)
      -- multiply by the number needed
      local multiplied_costs = multiply_ingredient_cost(costs, ingredient_amount)
      for _, c in ipairs(multiplied_costs) do
        table.insert(new_ingredients, c)
      end
    end
  end
  
  -- if we make more than 1, reduce the cost for that
  -- if the recipe makes multiple items, reduce the cost for that, too
  local count = get_recipe_result_count(recipe, item_name)
  local num_items = get_recipe_result_num_items(recipe)
  
  reduced = multiply_ingredient_cost(new_ingredients, (1 / count) / num_items)
  debug_log("item costs for a single " .. item_name .. " are: " .. stringify_table(reduced))
  
  -- cache it
  other_known_item_costs[item_name] = reduced
  return reduced
end

function find_recipe_for(item_name)
  -- @todo: there could be more than 1, we'd need to pick the "best" one
  for _, recipe in pairs(data.raw.recipe) do
    local results = find_result_items(recipe)
    for _, result_item in ipairs(results) do
      if result_item.name == item_name then
        return recipe
      end
    end
  end
end