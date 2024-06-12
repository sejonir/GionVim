local M = {}

function M.cmp_source(name, icon)
    local started = false
    local function status()
        if not package.loaded["cmp"] then
            return
        end
        for _, s in ipairs(require("cmp").core.sources) do
            if s.name == name then
                if s.source:is_available() then
                    started = true
                else
                    return started and "error" or nil
                end
                if s.status == s.SourceStatus.FETCHING then
                    return "pending"
                end
                return "ok"
            end
        end
    end

    local colors = {
        ok = GionVim.ui.fg("Special"),
        error = GionVim.ui.fg("DiagnosticError"),
        pending = GionVim.ui.fg("DiagnosticWarn"),
    }

    return {
        function()
            return icon or require("gionvim.config").icons.kinds[name:sub(1, 1):upper() .. name:sub(2)]
        end,
        cond = function()
            return status() ~= nil
        end,
        color = function()
            return colors[status()] or colors.ok
        end,
    }
end

function M.format(component, text, hl_group)
    text = text:gsub("%%", "%%%%")
    if not hl_group or hl_group == "" then
        return text
    end
    component.hl_cache = component.hl_cache or {}
    local lualine_hl_group = component.hl_cache[hl_group]
    if not lualine_hl_group then
        local utils = require("lualine.utils.utils")
        local gui = vim.tbl_filter(function(x)
            return x
        end, {
            utils.extract_highlight_colors(hl_group, "bold") and "bold",
            utils.extract_highlight_colors(hl_group, "italic") and "italic",
        })

        lualine_hl_group = component:create_hl({
            fg = utils.extract_highlight_colors(hl_group, "fg"),
            gui = #gui > 0 and table.concat(gui, ",") or nil,
        }, "LV_" .. hl_group)
        component.hl_cache[hl_group] = lualine_hl_group
    end
    return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

function M.pretty_path(opts)
    opts = vim.tbl_extend("force", {
        relative = "cwd",
        modified_hl = "MatchParen",
        directory_hl = "",
        filename_hl = "Bold",
        modified_sign = "",
        readonly_icon = " 󰌾 ",
        length = 3,
    }, opts or {})

    return function(self)
        local path = vim.fn.expand("%:p")

        if path == "" then
            return ""
        end
        local root = GionVim.root.get({ normalize = true })
        local cwd = GionVim.root.cwd()

        if opts.relative == "cwd" and path:find(cwd, 1, true) == 1 then
            path = path:sub(#cwd + 2)
        else
            path = path:sub(#root + 2)
        end

        local sep = package.config:sub(1, 1)
        local parts = vim.split(path, "[\\/]")

        if opts.length == 0 then
            parts = parts
        elseif #parts > opts.length then
            parts = { parts[1], "…", table.concat({ unpack(parts, #parts - opts.length + 2, #parts) }, sep) }
        end

        if opts.modified_hl and vim.bo.modified then
            parts[#parts] = parts[#parts] .. opts.modified_sign
            parts[#parts] = M.format(self, parts[#parts], opts.modified_hl)
        else
            parts[#parts] = M.format(self, parts[#parts], opts.filename_hl)
        end

        local dir = ""
        if #parts > 1 then
            dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
            dir = M.format(self, dir .. sep, opts.directory_hl)
        end

        local readonly = ""
        if vim.bo.readonly then
            readonly = M.format(self, opts.readonly_icon, opts.modified_hl)
        end
        return dir .. parts[#parts] .. readonly
    end
end

function M.root_dir(opts)
    opts = vim.tbl_extend("force", {
        cwd = false,
        subdirectory = true,
        parent = true,
        other = true,
        icon = "󱉭 ",
        color = GionVim.ui.fg("Special"),
    }, opts or {})

    local function get()
        local cwd = GionVim.root.cwd()
        local root = GionVim.root.get({ normalize = true })
        local name = vim.fs.basename(root)

        if root == cwd then
            return opts.cwd and name
        elseif root:find(cwd, 1, true) == 1 then
            return opts.subdirectory and name
        elseif cwd:find(root, 1, true) == 1 then
            return opts.parent and name
        else
            return opts.other and name
        end
    end

    return {
        function()
            return (opts.icon and opts.icon .. " ") .. get()
        end,
        cond = function()
            return type(get()) == "string"
        end,
        color = opts.color,
    }
end

return M
