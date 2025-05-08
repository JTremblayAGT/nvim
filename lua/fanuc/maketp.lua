-- FANUC TP Diagnostics module
local M = {}

function M.setup()
  local ns = vim.api.nvim_create_namespace('fanuc-tp-diagnostics')
  local jobId = 0

  local function run_maketp(tppfile, on_complete)
    -- Stop ongoing job
    local running = vim.fn.jobwait({ jobId }, 0)[1] == -1
    if running then
      local res = vim.fn.jobstop(jobId)
    end

    local cmd = 'maketp "' .. tppfile .. '"' -- Added quotes around the filename
    
    jobId = vim.fn.jobstart(
      cmd,
      {
        stdout_buffered = true,
        on_stdout = function(_, d)
          on_complete(d)
        end
      }
    )
  end

  local function parse_result(result)
    local diag = {}
    
    for i, line in ipairs(result) do
      -- Look for the pattern "on line XX, column YY"
      local line_num, col_num = line:match("on line (%d+), column (%d+)")
      
      if line_num and col_num then
        local msg = result[i + 1] or "Unknown error"
        
        -- Check if there's additional error information in subsequent lines
        local additional_info = result[i + 2]
        if additional_info and additional_info:match("Error executing MakeTP") then
          msg = msg .. " (" .. additional_info .. ")"
        end
        
        table.insert(diag, {
          lnum = tonumber(line_num) - 1, -- 0-based line numbering in Neovim
          col = tonumber(col_num) - 1,   -- 0-based column numbering in Neovim
          message = msg,
          severity = vim.diagnostic.severity.E,
        })
      end
    end
    
    return diag
  end

  local function callback_fn()
    -- Run maketp
    local bufname = vim.api.nvim_buf_get_name(0)
    
    -- Only process .ls files
    if not string.match(bufname, "%.ls$") then
      return
    end
    
    run_maketp(bufname, function(d)
      if not d or #d == 0 then
        vim.notify("No output from maketp", vim.log.levels.WARN)
        return
      end
      
      os.remove(string.gsub(bufname, ".ls", ".tp"))
      -- Parse output
      local diag = parse_result(d)
      
      -- Show notification about the results
      if #diag > 0 then
        vim.notify("Found " .. #diag .. " issues in " .. vim.fn.fnamemodify(bufname, ":t"), 
          vim.log.levels.WARN, {
            title = "FANUC TP Diagnostics",
            timeout = 3000,
          })
      else
        vim.notify("No issues found in " .. vim.fn.fnamemodify(bufname, ":t"), 
          vim.log.levels.INFO, {
            title = "FANUC TP Diagnostics",
            timeout = 1500,
          })
      end
      
      -- report diagnostics
      vim.diagnostic.set(ns, 0, diag, nil)
    end)
  end

  -- Set up the autocommand
  vim.api.nvim_create_autocmd({"BufWritePost"}, {
    pattern = {"*.ls"},
    desc = "Run maketp on .ls file",
    group = vim.api.nvim_create_augroup("FanucTpDiagnostics", { clear = true }),
    callback = function()
      callback_fn()
    end,
  })
  
  -- Create a global module for our plugin
  _G.maketp_diagnostics = {
    run_on_current_buffer = function()
      callback_fn()
    end
  }
  
  -- Add a user command to run maketp manually
  vim.api.nvim_create_user_command("Maketp", function()
    _G.maketp_diagnostics.run_on_current_buffer()
  end, { desc = "Run maketp diagnostics on current buffer" })
end

return M