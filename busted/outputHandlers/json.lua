local json = require("dkjson")
local io_write = io.write
local io_flush = io.flush

return function(options)
  local busted = require("busted")
  local handler = require("busted.outputHandlers.base")()

  handler.suiteEnd = function()
    local error_info = {
      pendings = handler.pendings,
      successes = handler.successes,
      failures = handler.failures,
      errors = handler.errors,
      duration = handler.getDuration(),
    }

    for _, test in ipairs(handler.pendings) do
      test.element.attributes.default_fn = nil -- functions cannot be encoded into json
    end

    local ok, result = pcall(json.encode, error_info, {
      exception = function(reason, value, state, default_reason)
        local state_short = table.concat(state.buffer, "")
        state_short = "..." .. state_short:sub(#state_short - 100) .. tostring(state.exception)
        io.stderr:write(default_reason .. "(" .. state_short .. ")")
      end,
    })

    if ok then
      io_write(result)
    else
      io_write("Failed to encode test results to json: " .. result)
      os.exit(1)
    end

    io_write("\n")
    io_flush()

    return nil, true
  end

  busted.subscribe({ "suite", "end" }, handler.suiteEnd)

  return handler
end
