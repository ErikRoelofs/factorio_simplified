function get_max_tier()
  local value = settings.startup["simplified-max-intermediate-tier"].value
  if value == "tier-0" then
    return 0
  elseif value == "tier-1" then
    return 1
  elseif value == "tier-2" then
    return 2
  elseif value == "tier-3" then
    return 3
  elseif value == "tier-4" then
    return 4
  elseif value == "tier-5" then
    return 5
  elseif value == "tier-6" then
    return 6
  elseif value == "tier-7" then
    return 7
  elseif value == "tier-8" then
    return 8
  elseif value == "tier-9" then
    return 9
  elseif value == "tier-10" then
    return 10
  elseif value == "tier-11" then
    return 11
  elseif value == "tier-12" then
    return 12
  elseif value == "tier-13" then
    return 13
  elseif value == "tier-14" then
    return 14
  end
  return 1
end

function get_tier_based_cost_reduction()
  local value = settings.startup["simplified-tier-based-cost-reduction"].value
  if value == "none" then
    return 1
  elseif value == "minor" then
    return 0.9
  elseif value == "decent" then
    return 0.8
  elseif value == "moderate" then
    return 0.7
  elseif value == "serious" then
    return 0.6
  elseif value == "immense" then
    return 0.5
  end
  return 1
end


function get_tier_based_cost_reduction_for_technology()
  local value = settings.startup["simplified-tier-based-cost-reduction-for-technology"].value
  if value == "none" then
    return 1
  elseif value == "minor" then
    return 0.95
  elseif value == "decent" then
    return 0.9
  elseif value == "moderate" then
    return 0.85
  elseif value == "serious" then
    return 0.8
  elseif value == "immense" then
    return 0.75
  end
  return 1
end

function get_crop_strategy()
  local value = settings.startup["simplified-item-count-crop-strategy"].value
  return value
end