local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Theme = loadstring and isfile and isfile("NewUi/Theme.lua")
	and (loadstring(readfile("NewUi/Theme.lua"))() or {}) or {}

local Library = {
	Theme = Theme,
	Windows = {},
	Connections = {},
	AccentHooks = {},
	Gradients = {},
	Font = Font.new("rbxassetid://12187370747", Enum.FontWeight.Regular),
}

Library.Theme = setmetatable(Theme, {
	__index = {
		Background = Color3.fromRGB(8, 8, 8),
		Panel = Color3.fromRGB(14, 14, 14),
		Card = Color3.fromRGB(18, 18, 18),
		Element = Color3.fromRGB(24, 24, 24),
		Pressed = Color3.fromRGB(38, 38, 38),
		RailOff = Color3.fromRGB(40, 40, 40),
		RailOn = Color3.fromRGB(255, 255, 255),
		Knob = Color3.fromRGB(10, 10, 10),
		Text = Color3.fromRGB(255, 255, 255),
		TextDim = Color3.fromRGB(160, 160, 160),
		Divider = Color3.fromRGB(58, 58, 58),
		Border = Color3.fromRGB(255, 255, 255),
		BorderAlpha = 0.12,
		MainColor = Color3.fromRGB(5, 5, 5),
		SecondaryColor = Color3.fromRGB(255, 255, 255),
		ThirdColor = nil,
		Mode = "Breathe",
	},
})

function Library:Accent()
	return self.Theme.SecondaryColor
end

local function Hook(func)
	table.insert(Library.AccentHooks, func)
	pcall(func)
	return func
end

function Library:RefreshTheme()
	for _, f in self.AccentHooks do
		pcall(f)
	end
end

local function Clr(c, alpha)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.new(c, c, c), Color3.new(1, 1, 1))
	g.Rotation = 45
	if alpha then
		g.Transparency = NumberSequence.new(alpha)
	end
	return g
end

local function Corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = obj
	return c
end

local function Stroke(obj, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 1
	s.Color = Library.Theme.Border or Color3.new(1, 1, 1)
	s.Transparency = transparency or Library.Theme.BorderAlpha or 0.12
	s.Parent = obj
	return s
end

local function New(className, props)
	local obj = Instance.new(className)
	for k, v in props do
		obj[k] = v
	end
	return obj
end

function Library:GetColor(pos)
	local t = self.Theme
	local x = pos and pos.X or 0
	local y = pos and pos.Y or 0
	local wave = math.sin(DateTime.now().UnixTimestampMillis / 600 + x * 0.005 + y * 0.06) * 0.5 + 0.5
	if t.ThirdColor then
		if wave <= 0.5 then
			return t.MainColor:Lerp(t.SecondaryColor, wave * 2)
		end
		return t.SecondaryColor:Lerp(t.ThirdColor, (wave - 0.5) * 2)
	end
	return t.SecondaryColor:Lerp(t.MainColor, wave)
end

local Bounds = Instance.new("GetTextBoundsParams")
Bounds.Font = Enum.Font.SourceSans
Bounds.Size = 16
Bounds.Width = 100000
Bounds.Height = 100000

function Library:GetFontSize(text, size, font, maxSize)
	Bounds.Text = text
	Bounds.Size = size
	if typeof(font) == "Font" then
		Bounds.Font = font
	end
	if maxSize then
		Bounds.Width = maxSize.X
		Bounds.Height = maxSize.Y
	end
	local ok, res = pcall(TextService.GetTextBoundsAsync, TextService, Bounds)
	return ok and res or Vector2.new(0, size)
end

local GradientFrame = 0
RunService.RenderStepped:Connect(function(dt)
	GradientFrame += dt
	if GradientFrame < 0.05 then
		return
	end
	GradientFrame = 0
	for g, _ in Library.Gradients do
		if g and g.Parent then
			local i = g.Parent
			local size = i.AbsoluteSize
			local pos = i.AbsolutePosition
			local pts = { ColorSequenceKeypoint.new(0, Library:GetColor(pos)) }
			if Library.Theme.ThirdColor then
				pts[2] = ColorSequenceKeypoint.new(0.5, Library:GetColor(pos + size * 0.25))
				pts[3] = ColorSequenceKeypoint.new(1, Library:GetColor(pos + size * 0.5))
			else
				pts[2] = ColorSequenceKeypoint.new(1, Library:GetColor(pos + size * 0.5))
			end
			g.Color = ColorSequence.new(pts)
		else
			Library.Gradients[g] = nil
		end
	end
end)

function Library:AddGradient(instance)
	local g = Instance.new("UIGradient")
	g.Rotation = 45
	g.Parent = instance
	Library.Gradients[g] = true
	return g
end

local function GetNotifyHolder()
	local root = LocalPlayer.PlayerGui:FindFirstChild("AkiraLiteUI")
	if not root then
		root = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
		root.Name = "AkiraLiteUI"
		root.IgnoreGuiInset = true
		root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end
	local holder = root:FindFirstChild("NotifyHolder")
	if not holder then
		holder = New("Frame", {
			Name = "NotifyHolder",
			Size = UDim2.new(0, 320, 1, -16),
			Position = UDim2.new(1, -12, 1, -12),
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 100,
		})
		local list = Instance.new("UIListLayout", holder)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.Padding = UDim.new(0, 6)
		holder.Parent = root
	end
	return holder
end

function Library:Notify(opts)
	opts = opts or {}
	local text = opts.Text or "None"
	local duration = opts.Duration or opts.Durn or 2
	local holder = GetNotifyHolder()

	local frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Library.Theme.Panel,
		BorderSizePixel = 0,
		LayoutOrder = -1,
	})
	Corner(frame, 6)
	Stroke(frame, 1, 0.2)
	local line = New("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = Library:Accent(),
		BorderSizePixel = 0,
	})
	Hook(function()
		line.BackgroundColor3 = Library:Accent()
	end)
	Corner(line, 2)
	line.Parent = frame

	local label = New("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Library.Font,
		TextSize = 13,
		TextWrapped = true,
	})
	label.Parent = frame

	frame.Parent = holder
	local sc = Instance.new("UIScale", frame)
	sc.Scale = 0
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1,
	}):Play()

	task.delay(duration, function()
		if not frame.Parent then
			return
		end
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
			Scale = 0,
		}):Play()
		label.TextTransparency = 1
		task.delay(0.3, function()
			frame:Destroy()
		end)
	end)
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			frame:Destroy()
		end
	end)
	return frame
end

-- ---------------------------------------------------------------------
-- Rows
-- ---------------------------------------------------------------------

local function FmtVal(v)
	local s = string.format("%.6f", v)
	s = s:gsub("0+$", ""):gsub("%.$", "")
	return s
end

local Row = {}

function Row.Toggle(holder, label, opts)
	opts = opts or {}
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
		BorderSizePixel = 0,
		LayoutOrder = holder._count + 1,
	})
	holder._count += 1
	Corner(row, 5)
	Stroke(row, 1, 0.08)
	row.Parent = holder

	local lbl = New("TextLabel", {
		Size = UDim2.new(1, -76, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Library.Font,
		TextSize = 13,
	})
	Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 10)
	lbl.Parent = row

	local rail = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(44, 22),
		BackgroundColor3 = Library.Theme.RailOff,
		BorderSizePixel = 0,
	})
	Corner(rail, 11)
	rail.Parent = row

	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Library.Theme.Knob,
		BorderSizePixel = 0,
	})
	Corner(knob, 9)
	Stroke(knob, 1, 0.35)
	knob.Parent = rail

	local tgl = { Value = opts.Default and true or false, Toggled = function() end, Row = row }

	local function Apply(v, instant)
		tgl.Value = v and true or false
		TweenService:Create(rail, TweenInfo.new(instant and 0 or 0.12), {
			BackgroundColor3 = tgl.Value and Library:Accent() or Library.Theme.RailOff,
		}):Play()
		TweenService:Create(knob, TweenInfo.new(instant and 0 or 0.12), {
			Position = tgl.Value and UDim2.fromScale(1, 0.5) or UDim2.fromScale(0, 0.5),
		}):Play()
	end

	Hook(function()
		if tgl.Value then
			rail.BackgroundColor3 = Library:Accent()
		end
	end)

	function tgl:Set(v, instant)
		Apply(v and true or false, instant)
	end

	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Apply(not tgl.Value)
			tgl.Toggled(tgl.Value)
		end
	end)

	return tgl
end

function Row.Slider(holder, label, opts)
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	local precision = opts.Decimal or opts.Precision or 1
	local suffix = opts.Suffix
	local def = opts.Default or min

	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
		BorderSizePixel = 0,
		LayoutOrder = holder._count + 1,
	})
	holder._count += 1
	Corner(row, 5)
	Stroke(row, 1, 0.08)
	row.Parent = holder

	local lbl = New("TextLabel", {
		Size = UDim2.new(1, -120, 0, 16),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Library.Font,
		TextSize = 13,
	})
	Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 10)
	lbl.Parent = row

	local val = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.fromOffset(100, 16),
		BackgroundTransparency = 1,
		Text = FmtVal(def),
		TextColor3 = Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Library.Font,
		TextSize = 12,
	})
	val.Parent = row

	local track = New("Frame", {
		Position = UDim2.new(0, 14, 0, 24),
		Size = UDim2.new(1, -28, 0, 3),
		BackgroundColor3 = Library.Theme.RailOff,
		BorderSizePixel = 0,
	})
	Corner(track, 2)
	track.Parent = row

	local fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Library:Accent(),
		BorderSizePixel = 0,
	})
	Corner(fill, 2)
	Hook(function()
		fill.BackgroundColor3 = Library:Accent()
	end)
	fill.Parent = track

	local ball = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Library.Theme.Knob,
		BorderSizePixel = 0,
	})
	Corner(ball, 6)
	Stroke(ball, 1, 0.3)
	ball.Parent = track

	local sld = { Value = def, Changed = function() end, Row = row }
	local dragging2 = false

	local function Display(v)
		local txt = FmtVal(v)
		if suffix then
			txt = txt .. " " .. (type(suffix) == "function" and suffix(v) or suffix)
		end
		val.Text = txt
	end

	local function Set(v, instant)
		v = math.clamp(v, min, max)
		sld.Value = v
		local rel = (max == min) and 0 or (v - min) / (max - min)
		Display(v)
		fill.Size = UDim2.fromScale(rel, 1)
		ball.Position = UDim2.fromScale(rel, 0.5)
	end

	function sld:Set(v, instant)
		Set(v, instant)
	end

	local function FromPosition(pos)
		local rel = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = math.floor((min + (max - min) * rel) * precision) / precision
		if v ~= sld.Value then
			Set(v)
			sld.Changed(sld.Value)
		end
	end

	ball.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging2 = true
			FromPosition(input.Position)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			FromPosition(input.Position)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging2 = false
		end
	end)

	if def then
		Set(def, true)
	end
	return sld
end

function Row.Dropdown(holder, label, opts)
	opts = opts or {}
	local options = opts.List or opts.Options or {}
	local def = opts.Default or options[1]
	local maxVisible = opts.MaxVisible or 6
	local optH = 22
	local contentH = math.min(#options, maxVisible) * optH

	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
		BorderSizePixel = 0,
		LayoutOrder = holder._count + 1,
		ZIndex = 2,
	})
	holder._count += 1
	Corner(row, 5)
	Stroke(row, 1, 0.08)
	row.Parent = holder

	local btn = New("TextButton", {
		Size = UDim2.new(1, -10, 1, -4),
		Position = UDim2.new(0, 5, 0, 2),
		BackgroundTransparency = 1,
		Text = "  " .. label .. "   [ " .. tostring(def) .. " ]",
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Library.Font,
		TextSize = 13,
		AutoButtonColor = false,
	})
	btn.Parent = row

	local drop = { Value = def, Changed = function() end, Row = row }
	local open = false

	local function RefreshLabel()
		btn.Text = "  " .. label .. "   [ " .. tostring(drop.Value) .. " ]"
	end

	local content = New("Frame", {
		Position = UDim2.new(0, 6, 0, 32),
		Size = UDim2.new(1, -12, 0, 0),
		BackgroundColor3 = Library.Theme.Background,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 5,
	})
	Corner(content, 5)
	Stroke(content, 1, 0.2)
	content.Parent = row

	local inner = New("ScrollingFrame", {
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, optH * maxVisible, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
	})
	local olist = Instance.new("UIListLayout", inner)
	olist.SortOrder = Enum.SortOrder.LayoutOrder
	inner.Parent = content

	local optionButtons = {}
	local function RecolorOptions()
		for _, o in optionButtons do
			o.TextColor3 = o.Name == tostring(drop.Value) and Library:Accent() or Library.Theme.TextDim
		end
	end

	for i, opt in options do
		local o = New("TextButton", {
			Name = tostring(opt),
			Size = UDim2.new(1, 0, 0, optH),
			BackgroundTransparency = 1,
			Text = "  " .. tostring(opt),
			TextColor3 = opt == drop.Value and Library:Accent() or Library.Theme.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Library.Font,
			TextSize = 12,
			AutoButtonColor = false,
		})
		o.Parent = inner
		optionButtons[i] = o
		o.MouseButton1Click:Connect(function()
			drop.Value = opt
			RefreshLabel()
			RecolorOptions()
			open = false
			content.Visible = false
			row.Size = UDim2.new(1, 0, 0, 30)
			drop.Changed(opt)
		end)
	end
	content.Size = UDim2.new(1, -12, 0, contentH + 8)
	Hook(RecolorOptions)

	function drop:Set(v)
		drop.Value = v
		RefreshLabel()
		RecolorOptions()
	end

	btn.MouseButton1Click:Connect(function()
		open = not open
		content.Visible = open
		row.Size = open and UDim2.new(1, 0, 0, 32 + contentH + 8) or UDim2.new(1, 0, 0, 30)
	end)

	return drop
end

function Row.Label(holder, text, opts)
	opts = opts or {}
	local row = New("Frame", {
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = holder._count + 1,
	})
	holder._count += 1
	local lbl = New("TextLabel", {
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = opts.TextColor3 or Library.Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Library.Font,
		TextSize = opts.TextSize or 12,
	})
	lbl.Parent = row
	row.Parent = holder
	return { Row = row }
end

function Row.Button(holder, label, opts)
	opts = opts or {}
	local row = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
		BorderSizePixel = 0,
		Text = "  " .. label,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		FontFace = Library.Font,
		TextSize = 13,
		LayoutOrder = holder._count + 1,
		AutoButtonColor = false,
	})
	holder._count += 1
	Corner(row, 5)
	Stroke(row, 1, 0.08)
	row.Parent = holder
	local obj = { Row = row, Clicked = opts.Function or opts.Clicked or function() end }
	row.MouseButton1Click:Connect(function()
		obj.Clicked()
	end)
	return obj
end

function Row.Card(holder, label, opts)
	opts = opts or {}
	local card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
		BorderSizePixel = 0,
		LayoutOrder = holder._count + 1,
	})
	holder._count += 1
	Corner(card, 6)
	Stroke(card, 1, 0.08)
	card.Parent = holder

	local clist = Instance.new("UIListLayout", card)
	clist.SortOrder = Enum.SortOrder.LayoutOrder
	clist.Padding = UDim.new(0, 4)

	local header = Row.Toggle(card, label, {
		Default = opts.Default,
	})

	local divider = New("Frame", {
		Size = UDim2.new(1, -16, 0, 1),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundColor3 = Library.Theme.Divider,
		BorderSizePixel = 0,
	})
	divider.Parent = card

	local body = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	})
	local bpad = Instance.new("UIPadding", body)
	bpad.PaddingBottom = UDim.new(0, 6)
	bpad.PaddingLeft = UDim.new(0, 8)
	bpad.PaddingRight = UDim.new(0, 8)
	local blist = Instance.new("UIListLayout", body)
	blist.SortOrder = Enum.SortOrder.LayoutOrder
	blist.Padding = UDim.new(0, 6)
	body._count = 0
	body.Parent = card

	local obj = {
		Frame = card,
		Row = card,
		Header = header,
		Body = body,
	}
	AttachRows(obj, body)
	return obj
end

-- attach row builder methods to a holder
local function AttachRows(obj, container)
	container._count = container._count or 0
	obj.ToggleRow = function(_, label, opts)
		return Row.Toggle(container, label, opts)
	end
	obj.SliderRow = function(_, label, opts)
		return Row.Slider(container, label, opts)
	end
	obj.DropdownRow = function(_, label, opts)
		return Row.Dropdown(container, label, opts)
	end
	obj.LabelRow = function(_, text, opts)
		return Row.Label(container, text, opts)
	end
	obj.ButtonRow = function(_, label, opts)
		return Row.Button(container, label, opts)
	end
	obj.Card = function(_, label, opts)
		return Row.Card(container, label, opts)
	end
	return obj
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------

function Library:Window(title, sideTabs)
	local root = LocalPlayer.PlayerGui:FindFirstChild("AkiraLiteUI")
	if not root then
		root = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
		root.Name = "AkiraLiteUI"
		root.IgnoreGuiInset = true
		root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end

	local dragOffset, dragging = Vector2.zero, false

	local main = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(620, 460),
		BackgroundColor3 = Library.Theme.Panel,
		BorderSizePixel = 0,
		Visible = false,
	})
	Corner(main, 8)
	Stroke(main, 1, 0.14)
	local mainScale = Instance.new("UIScale", main)
	mainScale.Scale = 1
	main.Parent = root

	local overlay = New("UIGradient", {
		Color = ColorSequence.new(Library.Theme.Panel, Color3.new(1, 1, 1)),
		Rotation = 45,
		Transparency = NumberSequence.new(0.96, 1),
	})
	overlay.Parent = main

	local titleBar = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		FontFace = Library.Font,
		TextSize = 14,
		TextTransparency = 0.15,
	})
	local pad = Instance.new("UIPadding", titleBar)
	pad.PaddingLeft = UDim.new(0, 12)
	titleBar.Parent = main

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragOffset = input.Position - main.AbsolutePosition
			dragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			main.Position = UDim2.fromOffset((input.Position - dragOffset).X, (input.Position - dragOffset).Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local sidebar = New("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(0, 160, 1, -44),
		BackgroundColor3 = Library.Theme.Background,
		BorderSizePixel = 0,
	})
	Corner(sidebar, 6)
	sidebar.Parent = main

	local pageHolder = New("Frame", {
		Position = UDim2.new(0, 168, 0, 36),
		Size = UDim2.new(1, -176, 1, -44),
		BackgroundTransparency = 1,
	})
	pageHolder.Parent = main

	local win = {
		Name = title,
		Main = main,
		Pages = {},
		CurrentPage = nil,
		Toggle = nil,
		Enabled = false,
	}

	function win:Toggle(show)
		win.Enabled = show and true or not win.Enabled
		if win.Enabled then
			main.Visible = true
		end
		TweenService:Create(mainScale, TweenInfo.new(0.18, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
			Scale = win.Enabled and 1 or 0,
		}):Play()
		if not win.Enabled then
			task.delay(0.18, function()
				if not win.Enabled then
					main.Visible = false
				end
			end)
		end
		return win.Enabled
	end

	local function Select(p)
		if win.CurrentPage == p then
			return
		end
		if win.CurrentPage then
			win.CurrentPage.Frame.Visible = false
			win.CurrentPage.Button.BackgroundColor3 = Library.Theme.Panel
			win.CurrentPage.Button.TextColor3 = Library.Theme.Text
		end
		p.Frame.Visible = true
		p.Button.BackgroundColor3 = Library:Accent()
		p.Button.TextColor3 = Color3.new(0, 0, 0)
		win.CurrentPage = p
	end

	Hook(function()
		if win.CurrentPage then
			win.CurrentPage.Button.BackgroundColor3 = Library:Accent()
		end
	end)

	function win:Page(name, icon)
		local btn = New("TextButton", {
			Size = UDim2.new(1, -8, 0, 26),
			BackgroundColor3 = Library.Theme.Panel,
			Text = "  " .. name,
			TextColor3 = Library.Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Library.Font,
			TextSize = 13,
			BorderSizePixel = 0,
			AutoButtonColor = false,
		})
		Corner(btn, 5)
		btn.Parent = sidebar
		Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 6)

		local page = New("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
		})
		page.Parent = pageHolder

		local list = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Color3.fromRGB(90, 90, 90),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
		})
		local lpad = Instance.new("UIPadding", list)
		lpad.PaddingTop = UDim.new(0, 6)
		lpad.PaddingBottom = UDim.new(0, 6)
		lpad.PaddingLeft = UDim.new(0, 6)
		lpad.PaddingRight = UDim.new(0, 6)
		local llayout = Instance.new("UIListLayout", list)
		llayout.SortOrder = Enum.SortOrder.LayoutOrder
		llayout.Padding = UDim.new(0, 6)
		list.Parent = page

		local pg = { Name = name, Frame = page, List = list, Button = btn, Elements = {} }
		list._count = 0
		AttachRows(pg, list)
		win.Pages[#win.Pages + 1] = pg

		btn.MouseButton1Click:Connect(function()
			Select(pg)
		end)

		if win.CurrentPage == nil then
			Select(pg)
		end
		return pg
	end

	Library.Windows[#Library.Windows + 1] = win
	if sideTabs then
		task.spawn(function()
			for _, p in win.Pages do
				Select(p)
				task.wait(0.02)
			end
		end)
	end
	return win
end

function Library:Unload()
	for _, win in Library.Windows do
		pcall(function()
			win.Main:Destroy()
		end)
	end
	for _, conn in Library.Connections do
		pcall(function()
			conn:Disconnect()
		end)
	end
	Library.Windows = {}
	Library.AccentHooks = {}
	Library.Gradients = {}
end

return Library