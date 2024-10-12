if vim.v.vim_did_enter ~= 1 then
    -- A trick to prevent calling setup before configuring it.
    vim.api.nvim_create_autocmd('VimEnter', {
        callback = function()
            require'mdmath'.setup()
        end,
    })
end
