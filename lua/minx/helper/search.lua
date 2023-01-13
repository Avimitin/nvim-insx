local syntax = require('minx.helper.syntax')

---@param open string
---@param close string
---@param flags string
---@return { [1]: integer, [2]: integer }
local function get_pair(open, close, flags)
  local in_string_or_comment = syntax.in_string_or_comment()
  return vim.fn.searchpairpos(open, '', close, flags, function()
    return in_string_or_comment ~= syntax.in_string_or_comment()
  end)
end

local search = {}

---@type table<string, string>
search.Tag = {
  Open = [=[<\(\w\+\)\%(\s\+.\{-}\)\?>]=],
  Close = [=[</\w\+>]=],
}

---Return most nearest wrapped pair's open position.
---@param open string
---@param close string
---@return { [1]: integer, [2]: integer }?
function search.get_pair_open(open, close)
  local open_pos = get_pair(open .. [[\zs]], close, 'Wbnz')
  if open_pos[1] ~= 0 then
    return { open_pos[1] - 1, open_pos[2] - 1 }
  end
end

---Return most nearest wrapped pair's close position.
---@param open string
---@param close string
---@return { [1]: integer, [2]: integer }?
function search.get_pair_close(open, close)
  local pos = get_pair(open, close, 'Wnzc')
  if pos[1] ~= 0 then
    return { pos[1] - 1, pos[2] - 1 }
  end
end

---Return most nearest next pattern position.
---@param pattern string
---@return { [1]: integer, [2]: integer }?
function search.get_next(pattern)
  local pos = vim.fn.searchpos(pattern, 'Wnzc')
  if pos[1] ~= 0 then
    return { pos[1] - 1, pos[2] - 1 }
  end
end

return search
