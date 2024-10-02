local api = vim.api

local M = {}

M.is_loaded = false

function M.setup(opts)
    if M.is_loaded then
        if opts then
            error("Attempt to setup mdmath.nvim (it's probably your plugin manager's fault, see " ..
                "README for more information)")
        end
        return
    end

    -- TODO: validate only enabled_filetypes
    local enabled_filetypes = opts and opts.enabled_filetypes or {'markdown'}

    local config = require'mdmath.config'
    config._set(opts)

    if enabled_filetypes[1] ~= nil then
        local group = api.nvim_create_augroup('MdMath', {clear = true})

        api.nvim_create_autocmd('FileType', {
            group = group,
            pattern = enabled_filetypes,
            callback = function()
                M.enable(0)
            end,
        })
    end

    M.is_loaded = true
end

-- function M.enable(bufnr)
--     if not M.is_loaded then
--         error "Attempt to call mdmath.nvim before it's loaded"
--     end

--     require 'mdmath.manager'.enable(bufnr or 0)
-- end

-- function M.disable(bufnr)
--     if not M.is_loaded then
--         error "Attempt to call mdmath.nvim before it's loaded"
--     end

--     require 'mdmath.manager'.disable(bufnr or 0)
-- end

return M
