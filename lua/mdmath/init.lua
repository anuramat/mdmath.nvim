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

    local filetypes = opts
        and opts.filetypes
        or {'markdown'}

    assert(type(filetypes) == 'table', 'filetypes: expected table, got ' .. type(filetypes))

    -- empty case: {}
    if filetypes[1] ~= nil then
        local group = api.nvim_create_augroup('MdMath', {clear = true})

        api.nvim_create_autocmd('FileType', {
            group = group,
            pattern = filetypes,
            callback = function()
                local bufnr = vim.api.nvim_get_current_buf()
                
                -- delay until next tick, since it's not needed for the UI
                vim.schedule(function()
                    if api.nvim_buf_is_valid(bufnr) then
                        M.enable(bufnr)
                    end
                end)
            end,
        })
    end

    require'mdmath.config'._set(opts)
    M.is_loaded = true
end

local function validate()
    if not M.is_loaded then
        error "Attempt to call mdmath.nvim before it's loaded"
    end
    require'mdmath.config'.validate()
end

function M.enable(bufnr)
    validate()
    require 'mdmath.manager'.enable(bufnr or 0)
end

function M.disable(bufnr)
    validate()
    require 'mdmath.manager'.disable(bufnr or 0)
end

return M
