-- string extensions.
-- life is too short; modify lua modules directly.

-- splits a string into a table of strings.
-- SELF a string to call split on.
-- MATCH is the string that will determine where to split. will not be included in the results.
-- OUT is an optional table to append results into.
-- the OUT table will contain the input string if no split point was found.
-- (string self, string match, ~table out) -> table
function string.split(self, match, out)
  local limit = #self + 1
  local last  = 1
  out = out or {}
  while last < limit do
    local next = string.find(self, match, last, true) or limit
    out[#out + 1] = string.sub(self, last, next - 1)
    last = next + #match
  end
  return out
end

return string
