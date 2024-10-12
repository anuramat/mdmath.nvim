local vim = vim
local util = require'mdmath.util'
local hl = require'mdmath.highlight-colors'
local tracker = require'mdmath.tracker'
local nvim = require'mdmath.nvim'
local config = require'mdmath.config'.opts

local ns = nvim.create_namespace('mdmath-marks')

local Mark = util.class 'Mark'
local buffers = {}
local num_buffers = 0

function Mark:_init(bufnr, row, col, opts)
    self.bufnr = bufnr
    self.opts = opts
    self.visible = false

    -- FIX: Currently, lines that are smaller than the current line doesn't override the
    --      text below it. Although this is not intended, I don't think it's worth fixing it now.
    if opts.lines then
        self.num_lines = #opts.lines

        self.lengths = {}
        for _, line in ipairs(opts.lines) do
            local length = line[2]
            table.insert(self.lengths, length)
        end

    else
        self.num_lines = 1
        self.lengths = { opts.text[2] }
    end

    local row_end, col_end 
    if self.num_lines > 1 then
        row_end = row + self.num_lines - 1
        col_end = self.lengths[self.num_lines]
    else
        row_end = row
        col_end = col + self.lengths[1]
    end

    self.pos = tracker.add(bufnr, row, col, row_end, col_end)
    self.pos.on_finish = function()
        self:remove()
    end
end

function Mark:remove()
    buffers[self.bufnr]:remove(self.id)
end

function Mark:contains(row, col)
    local srow, scol = unpack(self.pos)
    if self.num_lines == 1 then
        return srow == row and scol <= col and col < scol + self.lengths[1]
    end

    if row < srow or row >= srow + self.num_lines then
        return false
    end

    if row == srow then
        return col >= scol
    end

    if row == srow + self.num_lines - 1 then
        return col < self.lengths[self.num_lines]
    end

    return true
end

function Mark:_redraw()
    local row = self.pos[1]
    nvim._redraw({
        buf = self.bufnr,
        range = { row, row + self.num_lines },
    })
end

function Mark:set_visible(visible)
    if self.visible == visible then
        return
    end

    self.visible = visible
    self:_redraw()
end

local Buffer = util.class 'Buffer'

function Buffer:_init(bufnr)
    self.bufnr = bufnr
    self.marks = {}
    self._show = true
end

function Buffer:redraw()
    nvim._redraw({
        buf = self.bufnr,
        valid = false,
    })
end

function Buffer:add(mark)
    assert(mark.bufnr == self.bufnr)

    local id = #self.marks + 1
    mark.id = id
    self.marks[id] = mark

    mark:set_visible(true)
    return id
end

function Buffer:remove(id)
    local mark = self.marks[id]
    if mark then
        mark:set_visible(false)
        mark.pos:cancel()
        self.marks[id] = nil
    end
end

function Buffer:show(show)
    if self._show == show then
        return
    end

    assert(type(show) == 'boolean')
    self._show = show
    self:redraw()

    -- local bufnr = self.bufnr
    -- if not show then
    --     -- forcefully hide all marks without modifying visibility
    --     nvim.buf_clear_namespace(bufnr, ns, 0, -1)
    --     for _, mark in pairs(self.marks) do
    --         mark.id = nil -- do not change visibility, only forcefully hide
    --     end
    -- else
    --     for _, mark in pairs(self.marks) do
    --         mark:flush() -- flush visibility
    --     end
    -- end 
end

function Buffer:clear()
    self.marks = {}
    self:redraw()
end

do
    local function on_delete(opts)
        local bufnr = opts.buf
        if rawget(buffers, bufnr) ~= nil then
            buffers[bufnr] = nil
            num_buffers = num_buffers - 1
        end
    end

    local function on_cursor(opts)
        if not config.anticonceal then
            return
        end
        local buffer = buffers[opts.buf]
        local row, col = util.get_cursor()

        for _, mark in pairs(buffer.marks) do
            local visible = not mark:contains(row, col)
            mark:set_visible(visible)
        end
    end

    local function on_mode_change(opts)
        local buffer = buffers[opts.buf]
        local old_mode = vim.v.event.old_mode:sub(1, 1)
        local mode = vim.v.event.new_mode:sub(1, 1)
        if old_mode == mode then
            return
        end

        if mode == 'n' then
            on_cursor(opts)
        end

        local hide = config.hide_on_insert and (mode == 'i' or mode == 'R')
        buffer:show(not hide)
    end

    setmetatable(buffers, {
        __index = function(_, bufnr)
            if bufnr == 0 then
                return buffers[nvim.get_current_buf()]
            end

            nvim.create_autocmd({'BufWipeout'}, {
                buffer = bufnr,
                callback = on_delete,
            })

            nvim.create_autocmd({'ModeChanged'}, {
                buffer = bufnr,
                callback = on_mode_change,
            })

            nvim.create_autocmd({'CursorMoved'}, {
                buffer = bufnr,
                callback = on_cursor,
            })

            local buf = Buffer.new(bufnr)
            buffers[bufnr] = buf
            num_buffers = num_buffers + 1
            return buf
        end,
    })
end

-- TODO: This can be done once instead of every redraw
local function opts2extmark(opts)
    if opts.lines then
        local extmarks = {}
        for _, line in ipairs(opts.lines) do
            table.insert(extmarks, {
                virt_text = { { line[1], opts.color } },
                virt_text_pos = 'overlay',
                virt_text_hide = true,
                ephemeral = true,
                undo_restore = false,
            })
        end
        return extmarks, true
    else
        return {
            virt_text = { { opts.text[1], opts.color } },
            virt_text_pos = opts.text_pos,
            virt_text_hide = true,
            ephemeral = true,
            undo_restore = false,
        }, false
    end
end

function Mark:_draw()
    local extmarks, lines = opts2extmark(self.opts)
    local row, col = unpack(self.pos)

    if lines then
        for i, extmark in ipairs(extmarks) do
            nvim.buf_set_extmark(self.bufnr, ns, row, col, extmark)

            row = row + 1
            col = 0 -- reset col for next line
        end
    else
        nvim.buf_set_extmark(self.bufnr, ns, row, col, extmarks)
    end
end

function Mark:draw()
    if self.visible then
        local ok, err = pcall(self._draw, self)
        if not ok then
            vim.schedule(function()
                self:remove()
                nvim.err_writeln('mdmath: failed to draw mark: ' .. err)
            end)
        end
    end
end

local M = {}

function M.show(bufnr, show)
    show = show == nil and true or show
    buffers[bufnr]:show(show)
end

function M.add(bufnr, row, col, opts)
    bufnr = bufnr == 0 and nvim.get_current_buf() or bufnr

    if type(opts.color) == 'number' then
        opts.color = hl[opts.color]
    end
    opts.text_pos = opts.text_pos or 'overlay'

    local mark = Mark.new(bufnr, row, col, opts)
    return buffers[bufnr]:add(mark)
end

function M.remove(bufnr, id)
    buffers[bufnr]:remove(id)
end

function M.clear(bufnr)
    bufnr = bufnr or nvim.get_current_buf()
    buffers[bufnr]:clear()
end

do
    nvim.set_decoration_provider(ns, {
        on_start = function()
            if num_buffers == 0 then
                return false
            end
        end,
        on_win = function(_, _, bufnr)
            buffer = rawget(buffers, bufnr)
            if not buffer or not buffer._show then
                return false
            end

            for _, self in pairs(buffer.marks) do
                self:draw()
            end

            return false
        end,
    })
end

return M
