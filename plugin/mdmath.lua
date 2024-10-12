-- If your plugin manager calls `plugin` before `setup`, you may need to
-- disable auto setup to be able to configurate the plugin using require'mdmath'.setup {...}
if not vim.g.mdmath_disable_auto_setup then
    require'mdmath'.setup()
end
