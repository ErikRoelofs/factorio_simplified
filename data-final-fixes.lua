require "functions/debugging"
require "functions/functions"

-- remove productivity module restrictions, they'll crash the game
for k, v in pairs(data.raw.module) do
  if v.name:find("productivity%-module") then
    v.limitation = nil -- empty limitation table
    v.limitation_message_key = nil
  end
end

purged_recipes = {}
known_lowest = {
  "iron-ore", "copper-ore", "coal", "wood", "stone", "iron-plate", "copper-plate", "stone-brick", "plastic-bar", "sulfur", "steel-plate", "uranium-ore"
}
known_lowest_fluids = {
  "crude-oil", "water", "steam"
}

known_downgrades = {}
known_downgrades_fluids = {}

item_is_intermediate = {}
ingredient_tier = {}

for _, name in ipairs(known_lowest) do
  item_is_intermediate[name] = true
  ingredient_tier[name] = 0
end
for _, name in ipairs(known_lowest_fluids) do
  item_is_intermediate[name] = true
  ingredient_tier[name] = 0
end

ingredient_tier['steel-plate'] = 1
ingredient_tier['sulfur'] = 2
ingredient_tier['plastic-bar'] = 2

-- some stuff that the script doesn't get well (at least for now)
known_downgrades_fluids["light-oil"] = {{name = "crude-oil", amount = 10, type="fluid"}}
known_downgrades_fluids["heavy-oil"] = {{name = "crude-oil", amount = 10, type="fluid"}}
known_downgrades_fluids["petroleum-gas"] = {{name = "crude-oil", amount = 10, type="fluid"}}

known_downgrades["uranium-238"] = {{name = "uranium-ore", amount = 10}}
known_downgrades["uranium-235"] = {{name = "uranium-ore", amount = 1000}}

-- index the type of each item
for _, recipe in pairs(data.raw["recipe"]) do
  for _, item in pairs(find_result_items(recipe)) do
    item_is_intermediate[item.name] = is_intermediate(item)
  end
end

-- force bricks to be an intermediate to keep it in recipes
item_is_intermediate['stone-brick'] = true

-- index the tier of each item
for i = 1, 20 do
  for _, recipe in pairs(data.raw["recipe"]) do
    for _, item in pairs(find_result_items(recipe)) do
      if not ingredient_tier[item.name] then
        ingredient_tier[item.name] = determine_tier(find_ingredients(recipe), item)      
      end
    end
  end
end

local known_item_costs = {}
local new_recipe_costs = {}
for _, recipe in pairs(data.raw.recipe) do
  --if recipe.name == "refined-concrete" then
    debug_log("handling: " .. recipe.name)    
    local new_costs = determine_new_recipe_cost(recipe, known_item_costs, 1, 1)
    new_recipe_costs[recipe] = new_costs
    debug_log("final costs returned:")
    debug_log(stringify_table(new_costs))
  --end
end

-- update the costs for each recipe
for _, recipe in pairs(data.raw.recipe) do  
  replace_recipe_ingredients(recipe, new_recipe_costs[recipe])
end

-- strip out intermediate recipes, downgrade everything else
for recipe_key, recipe in pairs(data.raw["recipe"]) do  
  if should_remove_recipe(recipe) then
    table.insert(purged_recipes, recipe_key)
    data.raw["recipe"][recipe_key] = nil
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
  maybe_modify_category(recipe)  
 
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