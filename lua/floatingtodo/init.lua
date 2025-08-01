local M = {}

local win = nil

local default_opts = {
	target_file = "~/notes/todo.md",
	border = "single",
	width = 0.8,
	height = 0.8,
	position = "center",
}

local function expand_path(path)
	if path:sub(1, 1) == "~" then
		return os.getenv("HOME") .. path:sub(2)
	end
	return path
end

local function calculate_position(position)
	local posx, posy = 0.5, 0.5

	-- Custom position
	if type(position) == "table" then
		posx, posy = position[1], position[2]
	end

	-- Keyword position
	if position == "center" then
		posx, posy = 0.5, 0.5
	elseif position == "topleft" then
		posx, posy = 0, 0
	elseif position == "topright" then
		posx, posy = 1, 0
	elseif position == "bottomleft" then
		posx, posy = 0, 1
	elseif position == "bottomright" then
		posx, posy = 1, 1
	end
	return posx, posy
end

local function win_config(opts)
	local width = math.min(math.floor(vim.o.columns * opts.width), 64)
	local height = math.floor(vim.o.lines * opts.height)

	local posx, posy = calculate_position(opts.position)

	local col = math.floor((vim.o.columns - width) * posx)
	local row = math.floor((vim.o.lines - height) * posy)

	return {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		border = opts.border,
	}
end

local function open_floating_file(opts)
	if win ~= nil and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_set_current_win(win)
		return
	end

	local expanded_path = expand_path(opts.target_file)

	if vim.fn.filereadable(expanded_path) == 0 then
		vim.notify("todo file does not exist at directory: " .. expanded_path, vim.log.levels.ERROR)
		return
	end

	local buf = vim.fn.bufnr(expanded_path, true)

	if buf == -1 then
		buf = vim.api.nvim_create_buf(false, false)
		vim.api.nvim_buf_set_name(buf, expanded_path)
	end

	vim.bo[buf].swapfile = false

	win = vim.api.nvim_open_win(buf, true, win_config(opts))

	vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
		noremap = true,
		silent = true,
		callback = function()
			if vim.api.nvim_get_option_value("modified", { buf = buf }) then
				vim.api.nvim_buf_call(buf, function()
					vim.cmd("write")
				end)
			end
			vim.api.nvim_win_close(0, true)
			win = nil
		end,
	})
end

local function setup_user_commands(opts)
	opts = vim.tbl_deep_extend("force", default_opts, opts)

	vim.api.nvim_create_user_command("Td", function()
		open_floating_file(opts)
	end, {})
end

M.setup = function(opts)
	setup_user_commands(opts)
end

return M
