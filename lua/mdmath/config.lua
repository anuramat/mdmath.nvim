local default_opts = {
    filetypes = 'markdown',
    foreground = 'Normal',
    anticonceal = true,
    hide_on_insert = true,
    scale = 1.0,
}

local _opts = nil

local M = {
    _validated = false,
}
local mt = {
    __index = function()
        if _opts == nil then
            error 'mdmath.nvim opts have not been configured'
        elseif not M._validated then
            error 'mdmath.nvim opts have not been validated'
        else
            error 'mdmath.nvim bad index (this should not happen)'
        end
    end,
    __newindex = function()
        error 'Attempt to modify read-only mdmath.nvim opts'
    end,
}

function M.validate() 
    if M._validated then
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

    M._validated = true
    mt.__index = _opts
end

function M._set(opts)
    if _opts then
        error 'Attempt to configure mdmath.nvim opts multiple times (how did you even do that?)'
    end

    _opts = vim.tbl_extend('force', default_opts, opts or {})
end

setmetatable(M, mt)
return M
