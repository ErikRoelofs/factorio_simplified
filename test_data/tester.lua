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
