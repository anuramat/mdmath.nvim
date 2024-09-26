local api = vim.api

return setmetatable({}, {
    __index = function(self, key)
        self[key] = api['nvim_' .. key]
        return api['nvim_' .. key]
    end
})
