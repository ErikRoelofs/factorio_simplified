function log(msg)
  --print(msg)
end

settings = {startup = {}}
settings.startup["simplified-max-intermediate-tier"] = { value = "tier-1" }
settings.startup["simplified-tier-based-cost-reduction"] = { value = "none" }
settings.startup["simplified-tier-based-cost-reduction-for-technology"] = { value = "none" }
settings.startup["simplified-item-count-crop-strategy"] = { value = "onehalf" }

require "test_data/setup"
require "test_data/recipes"
require "test_data/fluids"
require "test_data/items"
require "test_data/technologies"
require "test_data/resources"

require "data-final-fixes"

-- validate some ingredients
local expectations = {}
expectations["inserter"] = {{ "iron-plate", 4 }, { "copper-plate", 2 }}
expectations["assembling-machine-1"] = {{ "iron-plate", 22 }, { "copper-plate", 5 }}
expectations["refined-concrete"] = {{ "stone-brick", 10 }, { "iron-ore", 2 }, {"water", 300}, {"iron-plate", 9}}

if not should_remove_item(find_item('iron-plate'), 0) then
  error("iron-plate should be removed at max-tier 0")
end
if should_remove_item(find_item('iron-plate'), 1) then
  error("iron-plate should not be removed at max-tier 1")
end

for name, ingredients in pairs(expectations) do
  local found = false
  for _, recipe in pairs(data.raw.recipe) do
    if recipe.name == name then
      validate(recipe, ingredients)
      found = true
    end
  end
  if not found then print("Recipe has gone missing: " .. name) end
end