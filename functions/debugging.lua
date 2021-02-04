function debug_log(text)
  log(text)
  --print(text)
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
