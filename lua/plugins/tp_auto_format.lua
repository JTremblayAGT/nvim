return {
  -- Custom plugin for TP file format
  {
    name = "tp-format", -- Depend on the TP syntax plugin you already have
    dir = vim.fn.stdpath("config") .. "/lua/plugins",
    dev = true,
    config = function()
      local tp_group = vim.api.nvim_create_augroup("TP_Autoformat", { clear = true })
      
      -- This autocmd detects when a new line is created in a TP file
      vim.api.nvim_create_autocmd({"InsertEnter"}, {
        group = tp_group,
        pattern = {"*.ls"},
        callback = function()
          -- Only run if filetype is tp
          if vim.bo.filetype ~= "tp" then
            return
          end
          
          -- Set up a one-time autocmd for InsertLeave or TextChangedI
          vim.api.nvim_create_autocmd({"InsertLeave", "TextChangedI"}, {
            group = tp_group,
            pattern = {"*.ls"},
            callback = function(args)
              -- Get current line number
              local line_nr = vim.api.nvim_win_get_cursor(0)[1]
              local current_line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1]
              
              -- Check if we're between /MN and /POS or /END
              local in_mn_section = false
              local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
              local mn_line = nil
              local pos_line = nil
              
              for i, line in ipairs(lines) do
                if line:match("/MN") then
                  mn_line = i
                elseif line:match("/POS") or line:match("/END") then
                  pos_line = i
                  break
                end
              end
              
              -- Check if current line is between /MN and /POS or /END
              if mn_line and pos_line and line_nr > mn_line and line_nr < pos_line then
                in_mn_section = true
              end
              
              -- If in the MN section and the line is empty, add the template
              if in_mn_section and current_line:match("^%s*$") then
                vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, {"   1:   ;"})
                -- Position cursor before the semicolon
                vim.api.nvim_win_set_cursor(0, {line_nr, 7})
              end
              
              -- Delete this one-time autocmd
              return true
            end,
            once = true,
          })
        end,
      })
    end,
  }
}