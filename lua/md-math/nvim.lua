local api = vim.api

return setmetatable({}, {
    __index = function(self, key)
        local s = api['nvim_' .. key]
        self[key] = s
        return s
    end
})
