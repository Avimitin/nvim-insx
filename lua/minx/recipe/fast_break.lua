local helper = require('minx.helper')

---@class minx.recipe.fast_break.Option
---@field public open_pat string
---@field public close_pat string

---@param option minx.recipe.fast_break.Option
---@return minx.RecipeSource
local function fast_break(option)
  return {
    ---@param ctx minx.ActionContext
    action = function(ctx)
      local open_indent = helper.indent.get_current_indent()
      ctx.send(ctx.char)
      ctx.send(helper.indent.ajudst_keys(helper.indent.get_current_indent(), open_indent .. helper.indent.get_one_indent()))
      local row, col = ctx.row(), ctx.col()
      local close_pos = helper.search.get_pair_close(option.open_pat, option.close_pat)
      assert(close_pos)
      ctx.move(close_pos[1], close_pos[2])
      ctx.send(ctx.char)
      ctx.send(helper.indent.ajudst_keys(helper.indent.get_current_indent(), open_indent))
      ctx.move(row, col)
    end,
    ---@param ctx minx.Context
    enabled = function(ctx)
      if helper.syntax.in_string_or_comment() then
        return false
      end
      local before = helper.regex.match(ctx.before(), option.open_pat .. [[\s*$]])
      if not before then
        return false
      end
      local close_pos = helper.search.get_pair_close(option.open_pat, option.close_pat)
      if not close_pos or close_pos[1] ~= ctx.row() then
        return false
      end
      return true
    end,
  }
end

return fast_break
