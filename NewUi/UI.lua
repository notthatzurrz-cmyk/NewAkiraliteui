local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local Theme = loadstring and isfile and isfile("NewUi/Theme.lua")
	and (loadstring(readfile("NewUi/Theme.lua"))() or {}) or {}

local Library = {
	Theme = Theme,
	Windows = {},
	Connections = {},
	Font = Font.new("rbxassetid://12187370747", Enum.FontWeight.Regular),
}

Library.Theme = setmetatable(Theme, {
	__index = {
		Background = Color3.fromRGB(8, 8, 8),
		Panel = Color3.fromRGB(14, 14, 14),
		Element = Color3.fromRGB(24, 24, 24),
		Text = Color3.fromRGB(255, 255, 255),
	},
})

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
	s.Color = Color3.new(1, 1, 1)
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
		Size = UDim2.fromOffset(560, 400),
		BackgroundColor3 = Library.Theme.Panel,
		BorderSizePixel = 0,
		Visible = false,
	})
	Corner(main, 8)
	Stroke(main, 1, 0.14)
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

	local layout = New("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal })
	layout.Padding = UDim.new(0, 8)
	layout.Parent = main

	local sidebar = New("Frame", {
		Position = UDim2.fromOffset(0, 36),
		Size = UDim2.new(0, 150, 1, -44),
		BackgroundColor3 = Library.Theme.Background,
		BorderSizePixel = 0,
	})
	Corner(sidebar, 6)
	sidebar.Parent = main

	local pageHolder = New("Frame", {
		Position = UDim2.new(0, 158, 0, 36),
		Size = UDim2.new(1, -166, 1, -44),
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
		main.Visible = win.Enabled
		return win.Enabled
	end

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
		local list = Instance.new("UIListLayout", page)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Padding = UDim.new(0, 6)
		page.Parent = pageHolder

		local pg = { Name = name, Frame = page, Elements = {} }
		win.Pages[#win.Pages + 1] = pg

		local white = Color3.new(1, 1, 1)
		local gray = Color3.fromRGB(150, 150, 150)
		btn.MouseButton1Click:Connect(function()
			for _, p in win.Pages do
				p.Frame.Visible = false
				p.Button.BackgroundColor3 = Library.Theme.Panel
				p.Button.TextColor3 = gray
			end
			page.Visible = true
			btn.BackgroundColor3 = white
			btn.TextColor3 = Color3.new(0, 0, 0)
			win.CurrentPage = pg
		end)

		pg.Button = btn
		if win.CurrentPage == nil then
			btn.MouseButton1Click:Fire()
		end

		function pg:ToggleRow(label)
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
				BorderSizePixel = 0,
				LayoutOrder = #pg.Elements + 1,
			})
			Corner(row, 5)
			Stroke(row, 1, 0.08)
			row.Parent = page

			local lbl = New("TextLabel", {
				Size = UDim2.new(1, -76, 1, 0),
				BackgroundTransparency = 1,
				Text = label,
				TextColor3 = Library.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
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

			local tgl = { Value = false, Toggled = function() end }

			local function Apply(v, instant)
				tgl.Value = v and true or false
				TweenService:Create(rail, TweenInfo.new(instant and 0 or 0.12), {
					BackgroundColor3 = tgl.Value and Library.Theme.RailOn or Library.Theme.RailOff,
				}):Play()
				TweenService:Create(knob, TweenInfo.new(instant and 0 or 0.12), {
					Position = tgl.Value and UDim2.fromScale(1, 0.5) or UDim2.fromScale(0, 0.5),
				}):Play()
			end

			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					Apply(not tgl.Value)
					tgl.Toggled(tgl.Value)
				end
			end)

			pg.Elements[tgl] = row
			return tgl
		end

		function pg:SliderRow(label, min, max, def)
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
				BorderSizePixel = 0,
				LayoutOrder = #pg.Elements + 1,
			})
			Corner(row, 5)
			row.Parent = page

			local lbl = New("TextLabel", {
				Size = UDim2.new(1, -110, 0, 14),
				BackgroundTransparency = 1,
				Text = label,
				TextColor3 = Library.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				TextSize = 13,
			})
			Instance.new("UIPadding", lbl).PaddingLeft = UDim.new(0, 10)
			lbl.Parent = row

			local val = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 3),
				Size = UDim2.fromOffset(90, 14),
				BackgroundTransparency = 1,
				Text = tostring(def),
				TextColor3 = Library.Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Right,
				FontFace = Library.Font,
				TextSize = 12,
			})
			val.Parent = row

			local track = New("Frame", {
				Position = UDim2.new(0, 14, 0, 20),
				Size = UDim2.new(1, -28, 0, 3),
				BackgroundColor3 = Library.Theme.RailOff,
				BorderSizePixel = 0,
			})
			Corner(track, 2)
			track.Parent = row

			local fill = New("Frame", {
				Size = UDim2.fromScale(0, 1),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			})
			Corner(fill, 2)
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

			local sld = { Value = def, Changed = function() end }
			local dragging2 = false

			local function SetFromPosition(pos)
				local rel = math.clamp((pos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				sld.Value = math.round(min + (max - min) * rel)
				val.Text = tostring(sld.Value)
				fill.Size = UDim2.fromScale(rel, 1)
				ball.Position = UDim2.fromScale(rel, 0.5)
				sld.Changed(sld.Value)
			end

			ball.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging2 = true
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging2 and input.UserInputType == Enum.UserInputType.MouseMovement then
					SetFromPosition(input.Position)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging2 = false
				end
			end)

			pg.Elements[sld] = row
			return sld
		end

		function pg:DropdownRow(label, options, def)
			def = def or options[1]
			local row = New("Frame", {
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundColor3 = Library.Theme.Card or Library.Theme.Element,
				BorderSizePixel = 0,
				LayoutOrder = #pg.Elements + 1,
			})
			Corner(row, 5)
			row.Parent = page

			local btn = New("TextButton", {
				Size = UDim2.new(1, -10, 1, -4),
				Position = UDim2.new(0, 5, 0, 2),
				BackgroundTransparency = 1,
				Text = "  " .. label .. "   [ " .. tostring(def) .. " ]",
				TextColor3 = Library.Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				FontFace = Library.Font,
				TextSize = 13,
			})
			btn.Parent = row

			local drop = { Value = def, Changed = function() end }
			local open = false

			local panel = New("Frame", {
				Position = UDim2.new(0, 0, 1, 4),
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundColor3 = Library.Theme.Background,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 5,
			})
			Corner(panel, 5)
			Stroke(panel, 1, 0.2)
			panel.Parent = row

			local optionButtons = {}
			for i, opt in options do
				local o = New("TextButton", {
					Size = UDim2.new(1, -8, 0, 22),
					Position = UDim2.new(0, 4, 0, 4 + (i - 1) * 24),
					BackgroundTransparency = 1,
					Text = "  " .. tostring(opt),
					TextColor3 = opt == drop.Value and Color3.new(1, 1, 1) or Library.Theme.TextDim,
					TextXAlignment = Enum.TextXAlignment.Left,
					FontFace = Library.Font,
					TextSize = 12,
				})
				o.Parent = panel
				optionButtons[#optionButtons + 1] = o
				o.MouseButton1Click:Connect(function()
					drop.Value = opt
					btn.Text = "  " .. label .. "   [ " .. tostring(opt) .. " ]"
					for _, child in optionButtons do
						if child.Text == "  " .. tostring(opt) then
							child.TextColor3 = Color3.new(1, 1, 1)
						else
							child.TextColor3 = Library.Theme.TextDim
						end
					end
					drop.Changed(opt)
				end)
			end

			btn.MouseButton1Click:Connect(function()
				open = not open
				panel.Visible = open
				panel.Size = UDim2.new(1, 0, 0, 4 + 24 * #options)
			end)

			pg.Elements[drop] = row
			return drop
		end

		return pg
	end

	Library.Windows[#Library.Windows + 1] = win
	return win
end

function Library:Unload()
	for _, win in Library.Windows do
		win.Main:Destroy()
	end
	for _, conn in Library.Connections do
		conn:Disconnect()
	end
	Library.Windows = {}
end

return Library