local Runner = require('minx.Runner')

---@param char string
---@return minx.Context
local function context(char)
  return {
    row = function()
      return vim.api.nvim_win_get_cursor(0)[1] - 1
    end,
    col = function()
      return vim.api.nvim_win_get_cursor(0)[2]
    end,
    char = char,
    text = function()
      return vim.api.nvim_get_current_line()
    end,
    before = function()
      local c = vim.api.nvim_win_get_cursor(0)[2]
      return vim.api.nvim_get_current_line():sub(1, c)
    end,
    after = function()
      local c = vim.api.nvim_win_get_cursor(0)[2]
      return vim.api.nvim_get_current_line():sub(c + 1)
    end,
  }
end

local minx = {}

minx.helper = require('minx.helper')

---@class minx.RecipeSource
---@field public action fun(ctx: minx.ActionContext): nil
---@field public enabled? fun(ctx: minx.Context): boolean
---@field public priority? integer

---@class minx.Context
---@field public char string
---@field public row fun(): integer 0-origin index
---@field public col fun(): integer 0-origin utf8 byte index
---@field public text fun(): string
---@field public after fun(): string
---@field public before fun(): string

---@class minx.ActionContext : minx.Context
---@field public send fun(keys: minx.kit.Vim.Keymap.KeysSpecifier): nil
---@field public move fun(row: integer, col: integer): nil

---@class minx.Recipe
---@field public index integer
---@field public action fun(ctx: minx.ActionContext): nil
---@field public enabled fun(ctx: minx.Context): boolean
---@field public priority integer

---@type table<string, minx.Recipe[]>
minx.recipes = {}

---Add new mapping recipe for specific mapping.
---@param char string
---@param recipe_source minx.RecipeSource
function minx.add(char, recipe_source)
  -- initialize mapping.
  if not minx.recipes[char] then
    minx.recipes[char] = {}

    vim.keymap.set('i', char, function()
      local ctx = context(char)
      local r = minx.get_recipe(ctx)
      if r then
        return Runner.new(ctx, r):run()
      end
      return char
    end, {
      expr = true,
    })
  end

  -- add normalized recipe.
  table.insert(minx.recipes[char], {
    index = #minx.recipes[char] + 1,
    action = recipe_source.action,
    enabled = recipe_source.enabled or function()
      return true
    end,
    priority = recipe_source.priority,
  })
end

---Get sorted/normalized entries for specific mapping.
---@param ctx minx.Context
---@return minx.Recipe|nil
function minx.get_recipe(ctx)
  local recipes = minx.recipes[ctx.char] or {}
  table.sort(recipes, function(a, b)
    if a.priority and b.priority then
      local diff = a.priority - b.priority
      if diff == 0 then
        return a.priority > b.priority
      end
    end
    return a.index < b.index
  end)
  for _, recipe in ipairs(recipes) do
    if recipe.enabled(ctx) then
      return recipe
    end
  end
end

return minx