local M = {}

---@class opencode.prompt.Opts
---@field session? "new" | "latest" Create a new session or use the most recently updated one. Defaults to "latest".

---@param prompt string
---@param context opencode.context.Context
---@param opts? opencode.prompt.Opts
---@return Promise<any>
function M.prompt(prompt, context, opts)
  local Promise = require("opencode.promise")
  return (
    prompt:match("%.%.%.$") and require("opencode.ui.ask").ask(prompt:gsub("%.%.%.$", ""), context)
    or Promise.resolve(prompt)
  )
    :next(function(_prompt)
      local plaintext = context:render(_prompt).output:plaintext()

      local session = opts and opts.session == "new" and context.server:create_session()
        or context.server:resolve_session()
      return session:next(function(session)
        return context.server:prompt(session.id, plaintext)
      end)
    end)
    :next(function()
      context:clear()
    end)
    :catch(function(err)
      context:resume()
      return Promise.reject(err)
    end)
end

return M
