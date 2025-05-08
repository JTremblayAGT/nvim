return {
  name = "tp-navigation",
  dir = vim.fn.stdpath("config") .. "/lua/plugins",
  dev = true,
  init = function()
    -- Create a namespace for our highlights
    local ns_id = vim.api.nvim_create_namespace("tp_label_navigation")
    
    -- Configuration with defaults
    local config = {
      highlight_color = "#6a9955", -- Default green color
      enabled_filetypes = { "tp" },
    }
    
    -- Function to update highlights in the current buffer
    local function update_highlights()
      local filetype = vim.bo.filetype
      -- Allow the plugin to work even if filetype is not explicitly set to tp
      -- as long as it's a .ls file
      if not vim.tbl_contains(config.enabled_filetypes, filetype) and vim.fn.expand("%:e") ~= "ls" then
        return
      end
      
      -- Clear existing highlights
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
      
      -- Get all lines in the buffer
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      
      -- Find all label declarations
      local labels = {}
      for i, line in ipairs(lines) do
        -- First try to match format with comment
        local line_num, label_num, comment = line:match("^%s*(%d+):%s*LBL%[([%w_]+):([^%]]*)]%s*;")
        
        -- If that didn't match, try without comment
        if not line_num then
          line_num, label_num = line:match("^%s*(%d+):%s*LBL%[([%w_]+)]%s*;")
          comment = nil
        end
        
        if line_num and label_num then
          -- Store the label and its line number and additional info
          table.insert(labels, {
            name = label_num,
            line_number = tonumber(line_num),
            comment = comment and comment:gsub("^%s*(.-)%s*$", "%1") or nil, -- Trim whitespace and store only if not empty
            line = i - 1, -- 0-based line indexing
            text = line
          })
          
          -- Fix highlighting - ensure we get exact character positions
          local start_idx = line:find("LBL%[")
          if start_idx then
            -- Highlight the entire LBL[...] declaration
            local end_idx = line:find("%]", start_idx) 
            if end_idx then
              -- Add 1 to end_idx to include the closing bracket
              vim.api.nvim_buf_add_highlight(0, ns_id, "TPLabelDeclaration", i-1, start_idx-1, end_idx)
            end
          end
        end
      end
      
      -- Store labels in buffer variable for navigation
      vim.b.tp_labels = labels
      
      -- Debug notification to show how many labels were found
      if #labels > 0 then
      end
    end
    
    -- Create autocmd group
    local augroup = vim.api.nvim_create_augroup("TPLabelNavigation", { clear = true })
    
    -- Set up autocmds to update highlights
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
      group = augroup,
      pattern = "*.ls",
      callback = update_highlights
    })
    
    -- Ensure highlight group is properly defined with enough visibility
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = augroup,
      callback = function()
        -- Redefine the highlight group after color scheme changes
        vim.api.nvim_set_hl(0, "TPLabelDeclaration", { 
          fg = config.highlight_color, 
          bold = true,
          underline = true  -- Add underline for more visibility
        })
      end
    })
    
    -- Define highlight group (initial definition)
    vim.api.nvim_set_hl(0, "TPLabelDeclaration", { 
      fg = config.highlight_color, 
      bold = true,
      underline = true  -- Add underline for more visibility
    })
    
    -- Setup navigation commands
    vim.api.nvim_create_user_command("TPNextLabel", function()
      local labels = vim.b.tp_labels
      if not labels or #labels == 0 then
        return
      end
      
      local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
      local next_label = nil
      
      -- Find the next label
      for _, label in ipairs(labels) do
        if label.line > current_line then
          next_label = label
          break
        end
      end
      
      -- If no next label, wrap around to the first one
      if not next_label and #labels > 0 then
        next_label = labels[1]
      end
      
      if next_label then
        vim.api.nvim_win_set_cursor(0, {next_label.line + 1, 0})
        vim.cmd("normal! zz") -- Center the cursor
      end
    end, {})
    
    vim.api.nvim_create_user_command("TPPrevLabel", function()
      local labels = vim.b.tp_labels
      if not labels or #labels == 0 then
        return
      end
      
      local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
      local prev_label = nil
      
      -- Find the previous label
      for i = #labels, 1, -1 do
        if labels[i].line < current_line then
          prev_label = labels[i]
          break
        end
      end
      
      -- If no previous label, wrap around to the last one
      if not prev_label and #labels > 0 then
        prev_label = labels[#labels]
      end
      
      if prev_label then
        vim.api.nvim_win_set_cursor(0, {prev_label.line + 1, 0})
        vim.cmd("normal! zz") -- Center the cursor
      end
    end, {})
    
    -- Function to show a popup with all labels in the current file
    vim.api.nvim_create_user_command("TPListLabels", function()
      local labels = vim.b.tp_labels
      if not labels or #labels == 0 then
        return
      end
      
      -- Create a new floating window
      local width = 70  -- Increased width to accommodate more information
      local height = #labels + 2
      local buf = vim.api.nvim_create_buf(false, true)
      
      local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        row = (vim.o.lines - height) / 2,
        col = (vim.o.columns - width) / 2,
        style = "minimal",
        border = "rounded",
        title = "TPP Labels",
        title_pos = "center"
      }
      
      -- Populate buffer with label information
      local lines = {}
      for i, label in ipairs(labels) do
        local comment_text = label.comment and (" - " .. label.comment) or ""
        table.insert(lines, string.format("%d: %s (line %d:%d)%s", 
          i, label.name, label.line + 1, label.line_number, comment_text))
      end
      
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      local win = vim.api.nvim_open_win(buf, true, win_opts)
      
      -- Set up keymaps for the popup
      vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
        callback = function()
          local line = vim.api.nvim_win_get_cursor(win)[1]
          local label = labels[line]
          if label then
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_win_set_cursor(0, {label.line + 1, 0})
            vim.cmd("normal! zz") -- Center the cursor
          end
        end,
        noremap = true
      })
      
      vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
        end,
        noremap = true
      })
      
      vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
        end,
        noremap = true
      })
    end, {})
    
    -- Set up config command to change highlight color
    vim.api.nvim_create_user_command("TPLabelHighlightColor", function(opts)
      local color = opts.args
      if color and color:match("^#%x%x%x%x%x%x$") then
        config.highlight_color = color
        vim.api.nvim_set_hl(0, "TPLabelDeclaration", { 
          fg = config.highlight_color, 
          bold = true,
          underline = true  -- Keep consistent with other definitions
        })
        update_highlights()
        vim.notify("Label highlight color updated to " .. color, vim.log.levels.INFO)
      else
        vim.notify("Invalid color format. Use hexadecimal format (e.g., #6a9955)", vim.log.levels.ERROR)
      end
    end, { nargs = 1 })
    
    -- Function to jump to label referenced by JMP instruction
    vim.api.nvim_create_user_command("TPJumpToLabel", function()
      -- Get the current line
      local line = vim.api.nvim_get_current_line()
      
      -- Check if this is a JMP LBL instruction
      -- Pattern matches lines like: "   1:  JMP LBL[TARGET];" or "   1:  JMP LBL[TARGET: comment];"
      local target_label = line:match("JMP%s+LBL%[([%w_]+)[:%]]")
      
      if not target_label then
        vim.notify("Not a JMP LBL instruction or label name not found", vim.log.levels.WARN)
        return
      end
      
      -- Look up the target label in our stored labels
      local labels = vim.b.tp_labels or {}
      local target = nil
      
      for _, label in ipairs(labels) do
        if label.name == target_label then
          target = label
          break
        end
      end
      
      if target then
        -- Jump to the target label
        vim.api.nvim_win_set_cursor(0, {target.line + 1, 0})
        vim.cmd("normal! zz") -- Center the cursor
      else
        vim.notify("Target label '" .. target_label .. "' not found in this file", vim.log.levels.WARN)
      end
    end, {})
    
    -- Add keymaps for navigation
    vim.keymap.set("n", "]l", "<cmd>TPNextLabel<CR>", { desc = "Next TPP Label" })
    vim.keymap.set("n", "[l", "<cmd>TPPrevLabel<CR>", { desc = "Previous TPP Label" })
    vim.keymap.set("n", "<leader>tl", "<cmd>TPListLabels<CR>", { desc = "List TPP Labels" })
    vim.keymap.set("n", "<leader>tj", "<cmd>TPJumpToLabel<CR>", { desc = "Jump to target label from JMP instruction" })
    
    -- Force an initial highlight update
    vim.defer_fn(function()
      update_highlights()
    end, 100)
  end,
}