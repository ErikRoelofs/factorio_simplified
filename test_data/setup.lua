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