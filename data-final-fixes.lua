require "functions/debugging"
require "functions/functions"
require "functions/settings"

force_keeps = {}
function force_keep(name)
  table.insert(force_keeps, name)
end

tier_overrides = {}
function override_tier(name, tier)
  table.insert(tier_overrides, {name, tier})
  table.insert(force_keeps, name)
end

require "exceptions"

-- remove productivity module restrictions, they'll crash the game
for k, v in pairs(data.raw.module) do
  if v.name:find("productivity%-module") then
    v.limitation = nil -- empty limitation table
    v.limitation_message_key = nil
  end
end

purged_recipes = {}
item_is_intermediate = {}

max_item_tier = get_max_tier()

debug_log("indexing item types; identifying intermediates")
-- index the type of each item
for _, recipe in pairs(data.raw["recipe"]) do
  for _, item in pairs(find_result_items(recipe)) do
    item_is_intermediate[item.name] = is_intermediate(item)
  end
end

-- force bricks to be an intermediate to keep it in recipes
item_is_intermediate['stone-brick'] = true

debug_log("determining full tier for each item")
-- determine full item tier for each item
item_tier = {}

for _, recipe in pairs(data.raw["recipe"]) do
  for _, item in pairs(find_result_items(recipe)) do    
    item_tier[item.name] = determine_full_tier(item.name, item_tier)
  end
end

debug_log("determining intermediate tier for each item")
intermediate_tier = {}

for _, exception in ipairs(tier_overrides) do  
  intermediate_tier[exception[1]] = exception[2]
end

for _, recipe in pairs(data.raw["recipe"]) do
  for _, item in pairs(find_result_items(recipe)) do
    intermediate_tier[item.name] = determine_intermediate_tier(item.name, intermediate_tier)
  end
end

debug_log("determining new costs for each recipe")
local known_item_costs = {}
local new_recipe_costs = {}
for _, recipe in pairs(data.raw.recipe) do
  local new_costs = determine_new_recipe_cost(recipe, known_item_costs, max_item_tier, 1, get_tier_based_cost_reduction())
  new_recipe_costs[recipe] = new_costs
end

debug_log("updating the costs for each recipe")
-- update the costs for each recipe
for _, recipe in pairs(data.raw.recipe) do  
  replace_recipe_ingredients(recipe, new_recipe_costs[recipe])
end

debug_log("removing unneccesary intermediates")
-- strip out intermediate recipes
for recipe_key, recipe in pairs(data.raw["recipe"]) do  
  if should_remove_recipe(recipe, max_item_tier) then
    table.insert(purged_recipes, recipe_key)
    data.raw["recipe"][recipe_key] = nil
  end
end

debug_log("eliminating recipes from technologies")
-- strip any removed items from technologies
for _, tech in pairs(data.raw["technology"]) do
  if tech.effects then
    local len = #tech.effects
    for i = len, 1, -1 do
      local effect = tech.effects[i]
      if effect.type == "unlock-recipe" then
        for _, purged in ipairs(purged_recipes) do
          if effect.recipe == purged then
            table.remove(tech.effects, i)
          end
        end
      end
    end
  end
end

debug_log("running some last fixed")
for _, recipe in pairs(data.raw["recipe"]) do  
  maybe_modify_category(recipe)  
 
  -- fix the rocket parts. I guess it either doesn't support fluid or more than 3 parts? Whatever, this works.
  if recipe.name == "rocket-part" then
    table.remove(recipe.ingredients, 4)
    table.remove(recipe.ingredients, 1)
  end
end

debug_log("updating resources that require fluids")
-- fix resources that need fluids for mining (ie; uranium ore)
for _, resource in pairs(data.raw["resource"]) do
  if resource.minable then
    if resource.minable.required_fluid then
      resource.minable.required_fluid = 'crude-oil'
    end
  end
end