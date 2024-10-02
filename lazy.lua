return {
    { 'nvim-treesitter/nvim-treesitter' },
    {
        'mdmath.nvim',
        init = function() 
            vim.g.mdmath_disable_auto_setup = true
        end,
        opts = {}
    }
}
