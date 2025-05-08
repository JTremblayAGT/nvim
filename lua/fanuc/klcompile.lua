-- Karel Language compilation functionality
local M = {}

function M.setup()
  local ns = vim.api.nvim_create_namespace('kl_compile')
  local jobId = 0

  local function run_ktrans(karelfile, on_complete)
    -- Stop ongoing job
    local running = vim.fn.jobwait({ jobId }, 0)[1] == -1
    if running then
      local res = vim.fn.jobstop(jobId)
    end

    local cmd = 'ktrans "' .. karelfile
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

  function M.compile()
    -- Run ktrans
    local bufname = vim.api.nvim_buf_get_name(0)
    run_ktrans(bufname, function(d)
      -- Get the compiled .pc file path
      local pc_file = string.gsub(bufname, ".kl", ".pc")
      local filename = vim.fn.fnamemodify(pc_file, ":t")
      
      -- Get current working directory and create target directory if it doesn't exist
      local cwd = vim.fn.getcwd()
      local target_dir = cwd .. "\\KAREL\\PC"
      
      local target_file = target_dir .. "\\" .. filename
      
      -- Check if target file exists and remove it before moving
      if vim.fn.filereadable(target_file) == 1 then
        os.remove(target_file)
      end
      
      -- Move the file using os.rename
      local success, err = os.rename(filename, target_file)
      
      if success then
        vim.notify("Moved compiled file to " .. target_file, vim.log.levels.INFO)
      else
        if vim.fn.filereadable(target_file) ~= 1 then
          vim.notify("File failed to compile", vim.log.levels.ERROR)
        else
          vim.notify("Failed to move compiled file: " .. (err or "unknown error"), vim.log.levels.ERROR)
        end
      end
    end)
  end

  -- Create the user command
  vim.api.nvim_create_user_command("KlCompile", M.compile, {})
  
  -- Set up the keymapping
  vim.keymap.set("n", "<leader>tk", "<cmd>KlCompile<CR>", { desc = "Compile Karel file" })
end

return M