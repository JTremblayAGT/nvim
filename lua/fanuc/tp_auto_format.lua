-- TP auto-formatting functionality
local M = {}

function M.setup()
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
            vim.api.nvim_buf_set_lines(0, line_nr - 1, line_nr, false, {"   1:  ;"})
            -- Position cursor before the semicolon
            vim.api.nvim_win_set_cursor(0, {line_nr, 8})
          end
          
          -- Delete this one-time autocmd
          return true
        end,
        once = true,
      })
    end,
  })

  -- Format the entire TP file on save
  vim.api.nvim_create_autocmd({"BufWritePre"}, {
    group = tp_group,
    pattern = {"*.ls"},
    callback = function()
      -- Only run if filetype is tp
      if vim.bo.filetype ~= "tp" then
        return
      end
      
      -- Format the file
      M.format_tp_file()
    end,
  })
end

-- Function to format the entire TP file
function M.format_tp_file()
  -- Get all lines in the buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  
  -- Find the /MN and /POS sections
  local mn_line = nil
  local pos_line = nil
  
  for i, line in ipairs(lines) do
    if line:match("^/MN") then
      mn_line = i
    elseif line:match("^/POS") or line:match("^/END") then
      pos_line = i
      break
    end
  end
  
  -- Only format if we found the /MN section
  if not mn_line or not pos_line then
    return
  end
  
  -- Keep the header (before /MN) and the footer (after /POS) intact
  local header = {}
  local mn_section = {}
  local footer = {}
  
  -- Extract the header
  for i = 1, mn_line do
    table.insert(header, lines[i])
  end
  
  -- Extract the footer
  for i = pos_line, #lines do
    table.insert(footer, lines[i])
  end
  
  -- Track indent level for control structures
  local indent_level = 0
  
  -- First pass: Calculate SELECT statement alignment positions
  local select_blocks = {}
  local current_select_start = nil
  
  for i = mn_line + 1, pos_line - 1 do
    local line = lines[i]
    
    -- Check if the line is a SELECT statement
    if line:match("SELECT%s+") then
      current_select_start = i
      select_blocks[current_select_start] = {
        cases = {},
        else_case = nil,
        max_equals_pos = 0,
        max_comma_pos = 0
      }
    end
    
    -- Check if the line is a SELECT case or ELSE branch
    if current_select_start then
      local content = ""
      if line:match("^%s*1:%s*(.*)") then
        content = line:match("^%s*1:%s*(.*)")
      else
        content = line
      end
      
      -- Check if this is an ELSE branch
      if content:match("^%s*ELSE,") then
        select_blocks[current_select_start].else_case = i
      -- Check if this is a regular case with equals sign
      elseif content:match("=%s*[^,]+,") then
        local equals_pos = content:find("=")
        local comma_pos = content:find(",")
        
        if equals_pos and equals_pos > select_blocks[current_select_start].max_equals_pos then
          select_blocks[current_select_start].max_equals_pos = equals_pos
        end
        
        if comma_pos and comma_pos > select_blocks[current_select_start].max_comma_pos then
          select_blocks[current_select_start].max_comma_pos = comma_pos
        end
        
        table.insert(select_blocks[current_select_start].cases, i)
      -- If it's not a case or ELSE and not a blank line, we're outside the SELECT
      elseif not content:match("^%s*$") and not content:match("^%s*SELECT") then
        current_select_start = nil
      end
    end
  end
  
  -- Second pass: Apply formatting
  for i = mn_line + 1, pos_line - 1 do
    local line = lines[i]
    
    -- Skip empty lines, comments, or documentation lines unchanged
    if line:match("^%s*$") or line:match("^%s*!") or line:match("^%s*%-%-eg:") then
      table.insert(mn_section, line)
    else
      -- Handle indentation for control structures that decrease indent
      if line:match("ENDIF") or line:match("ENDFOR")  then
        indent_level = math.max(0, indent_level - 1)
      end
      
      -- Standard prefix for all lines in MN section
      local standard_prefix = "   1:  "
      
      -- Extract content after standard prefix (if exists)
      local content = ""
      if line:match("^%s*1:%s*(.*)") then
        content = line:match("^%s*1:%s*(.*)")
      else
        content = line
      end
      
      local formatted_line = ""
      
      -- Special handling for motion instructions (J, L, C)
      if content:match("^%s*[JLC]%s+") then
        local motion_type = content:match("^%s*([JLC])")
        local rest = content:match("^%s*[JLC]%s+(.*)")
        
        -- For motion instructions, replace the standard space after "1:" with the motion type
        formatted_line = "   1:" .. string.rep(" ", indent_level * 4) .. motion_type .. " " .. rest
      else
        -- Check if this is a SELECT case line for alignment
        local is_select_case = false
        local is_else_branch = false
        local select_info = nil
        
        for select_start, info in pairs(select_blocks) do
          -- Check if this is a regular case
          for _, case_line in ipairs(info.cases) do
            if i == case_line then
              is_select_case = true
              select_info = info
              break
            end
          end
          
          -- Check if this is an ELSE branch
          if info.else_case and i == info.else_case then
            is_else_branch = true
            select_info = info
            break
          end
          
          if is_select_case or is_else_branch then break end
        end
        
        -- Clean content of existing indentation
        content = content:gsub("^%s*", "")
        
        -- Apply SELECT case alignment
        if is_select_case and select_info then
          local equals_pos = content:find("=")
          if equals_pos then
            local needed_spaces = select_info.max_equals_pos - equals_pos
            if needed_spaces > 0 then
              content = content:gsub("(=%s*)", string.rep(" ", needed_spaces) .. "%1")
            end
          end
          formatted_line = standard_prefix .. string.rep(" ", indent_level * 4) .. content
        -- Apply ELSE branch alignment
        elseif is_else_branch and select_info then
          -- For ELSE branch, align the comma with the max_comma_pos from regular cases
          local comma_pos = content:find(",")
          if comma_pos and select_info.max_comma_pos > 0 then
            -- Calculate how much space we need before ELSE to align the comma
            local needed_spaces = select_info.max_comma_pos - comma_pos
            if needed_spaces > 0 then
              -- Add spaces before ELSE instead of after it
              content = content:gsub("^(ELSE)", string.rep(" ", needed_spaces) .. "%1")
            end
          end
          formatted_line = standard_prefix .. string.rep(" ", indent_level * 4) .. content
        else
          formatted_line = standard_prefix .. string.rep(" ", indent_level * 4) .. content
        end
      end
      
      -- Check for structures that increase indentation
      if content:match("IF%s+.+THEN") or content:match("FOR%s+.+%s") then
        indent_level = indent_level + 1
      end
      
      -- Special case for ELSE (maintains same indentation as its IF)
      if content:match("^%s*ELSE%s*;") then
        -- Ensure we have exactly two spaces after "1:" plus indentation
        formatted_line = standard_prefix .. string.rep(" ", (indent_level - 1) * 4) .. "ELSE;"
      end
      
      -- Ensure there's always exactly one space before semicolons at the end of the line
      -- but don't change it if the line is essentially empty (just "1:" and whitespace and ";")
      if formatted_line:match(";%s*$") then
        -- Skip adjustment for empty lines with just whitespace between "1:" and ";"
        if not formatted_line:match("^%s*1:%s+;%s*$") then
          -- Remove any spaces before the semicolon and add exactly one
          formatted_line = formatted_line:gsub("%s*;%s*$", " ;")
        end
      end
      
      table.insert(mn_section, formatted_line)
    end
  end
  
  -- Combine the header, formatted MN section, and footer
  local formatted_lines = {}
  for _, line in ipairs(header) do
    table.insert(formatted_lines, line)
  end
  
  for _, line in ipairs(mn_section) do
    table.insert(formatted_lines, line)
  end
  
  for _, line in ipairs(footer) do
    table.insert(formatted_lines, line)
  end
  
  -- Replace buffer content with formatted lines
  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
  vim.notify("Formatted TPP file", vim.log.levels.INFO, {
    title = "TPP Autoformat",
    timeout = 1000,
  })
end

return M