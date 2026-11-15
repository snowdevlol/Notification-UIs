--[[
	Island Notification  ·  standalone
	Dark capsule at the top-center that expands in (Dynamic Island style).
	Lucide icons: https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua

	Usage:
		local Island = loadstring(game:HttpGet("https://raw.githubusercontent.com/snowdevlol/Notification-UIs/main/main/Island.lua"))()

		Island.notify({
			Title    = "Key verified",
			Message  = "Welcome back!",
			Kind     = "success",   -- "info" | "success" | "warn" | "error"
			Icon     = "check",     -- any Lucide icon name (optional)
			Duration = 3.5,
		})
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ───────────────────────── Config ─────────────────────────

local CONFIG = {
	Width = 260,
	Height = 52,
	MaxNotifs = 4,
	DefaultDuration = 3.5,
	TopOffset = 12,
	ICONS_URL = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
}

local COLORS = {
	info = Color3.fromRGB(88, 133, 255),
	success = Color3.fromRGB(52, 211, 118),
	warn = Color3.fromRGB(250, 189, 47),
	error = Color3.fromRGB(240, 82, 82),
}

local DEFAULT_ICON = {
	info = "info",
	success = "check",
	warn = "triangle-alert",
	error = "x",
}

local BG = Color3.fromRGB(0, 0, 0)
local BG_HOVER = Color3.fromRGB(22, 22, 26)
local BORDER = Color3.fromRGB(42, 42, 48)
local TEXT = Color3.fromRGB(244, 244, 245)
local MUTED = Color3.fromRGB(154, 154, 162)
local WHITE = Color3.fromRGB(255, 255, 255)
local DARK = Color3.fromRGB(11, 11, 11)

-- ───────────────────────── Lucide icons ─────────────────────────

local Icons
do
	local ok, result = pcall(function()
		return loadstring(game:HttpGet(CONFIG.ICONS_URL))()
	end)
	if ok and type(result) == "table" then
		Icons = result
	end
end

-- Returns { image, rectSize, rectOffset } or nil. Tolerates different return shapes.
local function resolveIcon(name)
	if not Icons or not name then
		return nil
	end

	local fn = Icons.Icon or Icons.GetIcon or Icons.Get
	if type(fn) ~= "function" then
		return nil
	end

	local ok, data = pcall(fn, name)
	if not ok or data == nil then
		ok, data = pcall(fn, name, "lucide")
	end
	if not ok or data == nil then
		return nil
	end

	if type(data) == "string" then
		return { image = data }
	end

	if type(data) == "table" then
		local image = data[1] or data.Image or data.Id or data.Asset
		local rect = data[2] or data
		if type(image) ~= "string" and type(image) ~= "number" then
			return nil
		end
		return {
			image = tostring(image),
			rectSize = rect.ImageRectSize or rect.RectSize,
			rectOffset = rect.ImageRectPosition or rect.ImageRectOffset or rect.RectPosition,
		}
	end

	return nil
end

-- ───────────────────────── Helpers ─────────────────────────

local function make(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function tween(inst, time, goal, style, dir)
	local t = TweenService:Create(
		inst,
		TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		goal
	)
	t:Play()
	return t
end

local function contrastOn(color)
	local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	return lum > 0.55 and DARK or WHITE
end

local FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local function getGuiParent()
	local ok, ui = pcall(function()
		return (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if ok and ui then
		return ui
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ───────────────────────── Root ─────────────────────────

local gui = make("ScreenGui", {
	Name = "IslandNotifications",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, getGuiParent())

local holder = make("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, CONFIG.TopOffset),
	Size = UDim2.new(0, CONFIG.Width, 1, -CONFIG.TopOffset * 2),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
}, gui)

make("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
}, holder)

-- ───────────────────────── Island ─────────────────────────

local Island = {}
local active = {}
local order = 0

function Island.notify(opts, message, kind, icon, duration)
	-- Accepts either a table or positional args: notify(title, message, kind, icon, duration)
	if type(opts) ~= "table" then
		opts = { Title = opts, Message = message, Kind = kind, Icon = icon, Duration = duration }
	end

	local title = tostring(opts.Title or "")
	local body = tostring(opts.Message or "")
	local k = COLORS[opts.Kind] and opts.Kind or "info"
	local color = COLORS[k]
	local dur = opts.Duration or CONFIG.DefaultDuration
	local W, H = CONFIG.Width, CONFIG.Height

	order += 1

	local wrapper = make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(0, W, 0, H + 8),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, holder)

	local toast = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -70),
		Size = UDim2.new(0, H, 0, H),
		BackgroundColor3 = BG,
		BackgroundTransparency = 0.06,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		ClipsDescendants = true,
		Text = "",
	}, wrapper)
	make("UICorner", { CornerRadius = UDim.new(0, H / 2) }, toast)
	local stroke = make("UIStroke", {
		Color = BORDER,
		Thickness = 1,
		Transparency = 0.35,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, toast)

	-- Content lives in a fixed-size CanvasGroup so it doesn't squish while the capsule expands
	local content = make("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, W, 0, H),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		GroupTransparency = 1,
	}, toast)

	local badge = make("Frame", {
		Position = UDim2.new(0, 10, 0, 10),
		Size = UDim2.new(0, 32, 0, 32),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, content)
	make("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)

	local iconColor = contrastOn(color)
	local spec = resolveIcon(opts.Icon or DEFAULT_ICON[k])
	if spec then
		local img = make("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 18, 0, 18),
			BackgroundTransparency = 1,
			Image = spec.image,
			ImageColor3 = iconColor,
		}, badge)
		if spec.rectSize then
			img.ImageRectSize = spec.rectSize
		end
		if spec.rectOffset then
			img.ImageRectOffset = spec.rectOffset
		end
	else
		-- Fallback glyph when icons can't be loaded
		make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = ({ info = "i", success = "✓", warn = "!", error = "✕" })[k],
			TextSize = 16,
			TextColor3 = iconColor,
			FontFace = FONT_BOLD,
		}, badge)
	end

	make("TextLabel", {
		Position = UDim2.new(0, 54, 0, 9),
		Size = UDim2.new(0, W - 70, 0, 16),
		BackgroundTransparency = 1,
		Text = title,
		TextSize = 13,
		TextColor3 = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = FONT_BOLD,
	}, content)

	make("TextLabel", {
		Position = UDim2.new(0, 54, 0, 27),
		Size = UDim2.new(0, W - 70, 0, 14),
		BackgroundTransparency = 1,
		Text = body,
		TextSize = 12,
		TextColor3 = MUTED,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		FontFace = FONT,
	}, content)

	-- ── Animations ──
	local function enter()
		tween(content, 0.25, { GroupTransparency = 0 })
		tween(toast, 0.4, { Position = UDim2.new(0.5, 0, 0, 0) }, Enum.EasingStyle.Quint)
		task.delay(0.12, function()
			if toast.Parent then
				tween(toast, 0.5, { Size = UDim2.new(0, W, 0, H) }, Enum.EasingStyle.Quint)
			end
		end)
	end

	local handle = {}
	local dismissed = false

	function handle.dismiss()
		if dismissed then
			return
		end
		dismissed = true

		local idx = table.find(active, handle)
		if idx then
			table.remove(active, idx)
		end

		tween(content, 0.25, { GroupTransparency = 1 })
		tween(
			toast,
			0.3,
			{ Size = UDim2.new(0, H, 0, H) },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.In
		)
		task.delay(0.15, function()
			if toast.Parent then
				tween(
					toast,
					0.3,
					{ Position = UDim2.new(0.5, 0, 0, -70) },
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.In
				)
			end
		end)
		task.delay(0.45, function()
			if wrapper.Parent then
				tween(wrapper, 0.2, { Size = UDim2.new(0, W, 0, 0) })
				task.delay(0.22, function()
					wrapper:Destroy()
				end)
			end
		end)
	end

	enter()

	-- ── Interaction ──
	local hovering, hoverSince = false, 0

	toast.MouseButton1Click:Connect(handle.dismiss)
	toast.MouseEnter:Connect(function()
		if dismissed then
			return
		end
		hovering = true
		hoverSince = os.clock()
		tween(toast, 0.15, { BackgroundColor3 = BG_HOVER })
	end)
	toast.MouseLeave:Connect(function()
		if dismissed then
			return
		end
		hovering = false
		tween(toast, 0.15, { BackgroundColor3 = BG })
	end)

	-- ── Timer (pauses while hovering, up to 8s) ──
	task.spawn(function()
		local remaining = dur
		local last = os.clock()
		while not dismissed do
			task.wait(0.05)
			local now = os.clock()
			if not (hovering and now - hoverSince < 8) then
				remaining -= now - last
			end
			last = now
			if remaining <= 0 then
				handle.dismiss()
				break
			end
		end
	end)

	table.insert(active, handle)
	while #active > CONFIG.MaxNotifs do
		active[1].dismiss()
	end

	return handle
end

function Island.dismissAll()
	for i = #active, 1, -1 do
		active[i].dismiss()
	end
end

function Island.Destroy()
	Island.dismissAll()
	gui:Destroy()
end

return Island
