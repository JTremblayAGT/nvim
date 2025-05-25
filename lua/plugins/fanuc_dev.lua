-- Load all custom modules
return {
  "fanuc-dev",
  name = "fanuc-dev",
  dir = vim.fn.stdpath("config") .. "/lua/fanuc",
  lazy = false, -- Ensure it's not lazy loaded
  priority = 1000, -- High priority to load early
  config = function()
    -- Load the TP Auto Format module
    require("fanuc.tp_auto_format").setup()

    -- Load the Karel Compile module
    require("fanuc.klcompile").setup()

    -- Load the maketp diagnostics module
    --require("fanuc.maketp").setup()

    -- Load the checktp module
    --require("fanuc.checktp").setup()

    -- Load the TP navigation module
    require("fanuc.tp_navigation").setup()

    -- You can add more custom modules here
    -- require("custom.your_module").setup()

    vim.notify("Fanuc Dev Plugin loaded", vim.log.levels.INFO)
  end,
}
