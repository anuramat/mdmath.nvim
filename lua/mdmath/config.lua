local default_opts = {
    filetypes = 'markdown',
    foreground = 'Normal',
    anticonceal = true,
    hide_on_insert = true,
    scale = 1.0,
}

local _opts = nil

local M = {
    validated = false,
}

local mt = {
    __index = function(_, key)
        if key ~= 'opts' then
            return nil
        end

        if _opts == nil then
            error 'mdmath.nvim has not been configured'
        end

        M.validate()
        return _opts
    end,
    __newindex = function()
        error 'Attempt to modify read-only mdmath.nvim config'
    end,
}

function M.validate() 
    if M.validated then
        return
    end
    if _opts == nil then
        error "Attempt to validate mdmath.nvim before configuring it (see README for more information)"
    end
    local opts = _opts

    vim.validate {
        foreground = {opts.foreground, 'string'},
        anticonceal = {opts.anticonceal, 'boolean'},
        hide_on_insert = {opts.hide_on_insert, 'boolean'},
    }

    opts.foreground = require'mdmath.util'.hl_as_hex(opts.foreground)

    setmetatable(opts, {
        __newindex = function()
            error 'Attempt to modify read-only mdmath.nvim opts'
        end,
    })

    M.validated = true
    rawset(M, 'opts', opts)
end

function M.set_opts(opts)
    if _opts then
        error 'Attempt to configure mdmath.nvim opts multiple times (how did you even do that?)'
    end

    _opts = vim.tbl_extend('force', default_opts, opts or {})
end

setmetatable(M, mt)
return M
