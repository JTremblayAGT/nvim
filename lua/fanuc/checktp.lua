-- Fanuc TP static analysis module
local M = {}

function M.setup()
  local ns = vim.api.nvim_create_namespace("checktp")
  local jobId = 0
  local function run_checktp(tppfile, on_complete)
    -- Stop ongoing job
    local running = vim.fn.jobwait({ jobId }, 0)[1] == -1
    if running then
      local res = vim.fn.jobstop(jobId)
    end

    local cmd = 'checktp "' .. tppfile .. '"' -- Added quotes around the filename

    jobId = vim.fn.jobstart(cmd, {
      stderr_buffered = true,
      on_stderr = function(_, d)
        on_complete(d)
      end,
    })
  end
  local function parse_result(result)
    local diag = {}

    for i, line in ipairs(result) do
      -- Skip empty lines and header information
      if
        line:match("^%s*$")
        or line:match("^=+%s*$")
        or line:match("^%-+%s*$")
        or line:match("^Analysis Results")
        or line:match("^File:")
        or line:match("^Summary")
      then
        -- Skip these lines
      else
        -- Check if line contains a diagnostic message
        if line:match("^%[") then
          -- Match the format: [Severity] Line XX: Message
          local severity, line_num, message = line:match("^%[(%w+)%]%s+Line%s+(%d+):%s+(.+)")
          local function get_severity(sevStr)
            if sevStr == "Warning" then
              return vim.diagnostic.severity.W
            elseif sevStr == "Error" then
              return vim.diagnostic.severity.E
            else
              return vim.diagnostic.severity.I
            end
          end

          if line_num and severity and message then
            table.insert(diag, {
              lnum = tonumber(line_num) - 1, -- Convert to 0-based line numbering for Neovim
              col = 0, -- 0-based column numbering in Neovim
              message = message,
              severity = get_severity(severity),
            })
          end
        end
      end
    end

    return diag
  end
  local function callback_fn()
    -- Run checktp
    local bufname = vim.api.nvim_buf_get_name(0)

    -- Only process .ls files (case insensitive)
    if not string.match(bufname:lower(), "%.ls$") then
      return
    end

    run_checktp(bufname, function(d)
      if not d or #d == 0 then
        vim.notify("No output from checktp", vim.log.levels.WARN)
        return
      end

      local diag = parse_result(d)

      -- report diagnostics
      vim.diagnostic.set(ns, 0, diag, nil)
    end)
  end
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    pattern = { "*.ls", "*.LS" },
    desc = "Run checktp on .ls file",
    group = vim.api.nvim_create_augroup("CheckTP", { clear = true }),
    callback = function()
      callback_fn()
    end,
  })
  -- Create a global module for our plugin
  _G.checktp_diagnostics = {
    run_on_current_buffer = function()
      callback_fn()
    end,
  }

  -- Add a user command to run checktp manually
  vim.api.nvim_create_user_command("Checktp", function()
    _G.checktp_diagnostics.run_on_current_buffer()
  end, { desc = "Run checktp on current buffer" })
end

return M

