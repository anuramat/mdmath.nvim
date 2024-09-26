local vim = vim
local nvim = require'md-math.nvim'
local uv = vim.loop
local marks = require'md-math.marks'
local util = require'md-math.util'
local Processor = require'md-math.Processor'
local Image = require'md-math.Image'
local tracker = require'md-math.tracker'

local Equation = util.new_class('Equation')

function Equation:__tostring()
    return '<Equation>'
end

function Equation:_create(res, err)
    if not res then
        local text = ' ' .. err
        local color = 'Error'
        vim.schedule(function()
            if self.valid then
                self.mark_id = marks.add(self.bufnr, self.pos[1], self.pos[2], {
                    text = { text, self.byte_len },
                    color = color,
                    text_pos = 'eol',
                })
                self.created = true
            end
        end)
        return
    end

    local image = Image.new(1, self.length, res)
    local text = image:text()[1]
    local color = image:color()

    vim.schedule(function()
        if self.valid then
            self.mark_id = marks.add(self.bufnr, self.pos[1], self.pos[2], {
                text = { text, self.byte_len },
                color = color,
                text_pos = 'overlay',
            })
            self.image = image
            self.created = true
        else -- free resources
            image:close()
        end
    end)
end

function Equation:_init(bufnr, row, col, text, byte_len)
    bufnr = (bufnr == nil or bufnr == 0) and nvim.get_current_buf() or bufnr
    if text:find('\n') or text:find('\r') then
        error('multiline equations are currently not supported :(')
    end

    self.bufnr = bufnr
    -- TODO: pos should be shared with the mark
    self.pos = tracker.add(bufnr, row, col, byte_len)
    self.pos.on_finish = function()
        self:invalidate()
    end

    self.text = text
    self.byte_len = byte_len
    self.length = util.strwidth(text)
    self.created = false
    self.valid = true
    
    -- remove trailing '$'
    self.equation = text:gsub('^%$*(.-)%$*$', '%1')

    local processor = Processor.from_bufnr(bufnr)
    processor:request(self.equation, function(res, err)
        if self.valid then
            self:_create(res, err)
        end
    end)
end

-- TODO: should we call invalidate() on '__gc'?
function Equation:invalidate()
    if not self.valid then
        return
    end
    self.valid = false
    if not self.created then
        return
    end

    -- UU.notify('Invalidating', self.text)

    self.pos:cancel()
    marks.remove(self.bufnr, self.mark_id)
    self.mark_id = nil
end

return Equation
