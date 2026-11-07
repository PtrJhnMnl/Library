# Ssamachi UI Library

## Installation

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/PtrJhnMnl/Library/refs/heads/main/Ssamachi.lua"))()
```

---

## Creating a Window

```lua
local Window = Ssamachi:CreateWindow({
    Title = "My Hub",
    SubTitle = "v1.0",
    Icon = "home-20-filled",
    Image = "rbxassetid://1234567890",
    Size = UDim2.fromOffset(600, 400),
    TabWidth = 180,
    MinimizeKey = Enum.KeyCode.LeftControl,
    AutoConfig = "myconfig",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Window title shown in the title bar |
| `SubTitle` | `string` | `nil` | Secondary text next to the title |
| `Icon` | `string \| number` | `nil` | Title bar icon (see [Icons](#icons)) |
| `Image` | `string` | `nil` | Large image displayed above the sidebar tabs |
| `Size` | `UDim2` | `nil` | Initial window size |
| `TabWidth` | `number` | `nil` | Sidebar width in pixels |
| `MinimizeKey` | `Enum.KeyCode` | `LeftControl` | Key to hide/show the UI |
| `AutoConfig` | `string` | `nil` | Enables automatic config saving with this name |

> Search is always enabled — no configuration required.

---

## Tabs

```lua
local Tab = Window:AddTab({
    Title = "Main",
    Icon = "home-20-filled",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Tab display name |
| `Icon` | `string \| number` | `nil` | Tab icon |

### Selecting a Tab Programmatically

```lua
Window:SelectTab(Tab)  -- by Tab object
Window:SelectTab(1)    -- by index
```

### SubTabs

```lua
local SubTab = Tab:AddSubTab({
    Title = "Aimbot",
    Icon = "crosshair-20-filled",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | SubTab display name |
| `Icon` | `string \| number` | `nil` | SubTab icon |

> When a SubTab exists, `Tab:AddSection(...)` automatically routes to the currently selected SubTab.

---

## Sections

```lua
local Section = Tab:AddSection({
    Title = "Combat",
    Icon = "sword-20-filled",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Section header text |
| `Icon` | `string \| number` | `nil` | Section icon |

---

## Elements

All elements accept the following common arguments:

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Element title |
| `Description` | `string` | `nil` | Secondary description |
| `Icon` | `string \| number` | `nil` | Element icon (except Dropdown/Slider/Input) |

### Button

```lua
Section:AddButton({
    Title = "Click Me",
    Description = "Does something cool",
    Icon = "cursor-click-20-filled",
    Callback = function()
        print("clicked")
    end,
})
```

### Toggle

```lua
local Toggle = Section:AddToggle(1, {
    Title = "Enabled",
    Description = "Turn it on or off",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `boolean` | `false` | Initial value |
| `Callback` | `function` | `nil` | Called with the new value |

**Methods**

```lua
Toggle:SetValue(true)                  -- set value programmatically
Toggle:OnChanged(function(Value) end)  -- register change listener
Toggle:Destroy()                       -- remove the element
```

### Slider

```lua
local Slider = Section:AddSlider(2, {
    Title = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value) end,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `number` | required | Initial value |
| `Min` | `number` | required | Minimum value |
| `Max` | `number` | required | Maximum value |
| `Rounding` | `number` | required | Decimal places (`0` = integer) |

**Methods**

```lua
Slider:SetValue(50)
Slider:OnChanged(function(Value) end)
Slider:Destroy()
```

### Dropdown

```lua
local Dropdown = Section:AddDropdown(3, {
    Title = "Mode",
    Values = { "One", "Two", "Three" },
    Default = "One",
    Multi = false,
    AllowNull = false,
    KeepSearch = false,
    Callback = function(Value) end,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Values` | `table` | required | List of options |
| `Default` | `string \| table` | `nil` | Initial selection |
| `Multi` | `boolean` | `false` | Allow multiple selections |
| `AllowNull` | `boolean` | `false` | Allow deselecting all (Multi) |
| `KeepSearch` | `boolean` | `false` | Preserve search text after closing |

**Methods**

```lua
Dropdown:SetValue("Two")
Dropdown:SetValues({ "A", "B", "C" })
Dropdown:GetActiveValues()
Dropdown:OnChanged(function(Value) end)
Dropdown:Destroy()
```

### Keybind

```lua
local Keybind = Section:AddKeybind(4, {
    Title = "Aim Key",
    Default = "E",
    Mode = "Toggle",
    Callback = function(State) end,
    ChangedCallback = function(NewKey) end,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `string` | required | Initial key name (`"E"`, `"MouseRight"`, ...) |
| `Mode` | `string` | `"Toggle"` | `"Toggle"`, `"Hold"`, or `"Always"` |

**Methods**

```lua
Keybind:GetState()                        -- returns current boolean state
Keybind:SetValue("F", "Hold")
Keybind:OnChanged(function(Key) end)
Keybind:OnClick(function(State) end)
Keybind:Destroy()
```

### Colorpicker

```lua
local Picker = Section:AddColorpicker(5, {
    Title = "Accent Color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = true,
    Callback = function(Color) end,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `Color3` | required | Initial color |
| `Transparency` | `boolean` | `false` | Enable alpha/transparency slider |

**Methods**

```lua
Picker:SetValueRGB(Color3.fromRGB(0, 255, 0), 0.5)
Picker:SetValue({ 0.5, 1, 1 }, 0)  -- HSV + transparency
Picker:OnChanged(function(Color) end)
Picker:Destroy()
```

### Input

```lua
local Input = Section:AddInput(6, {
    Title = "Name",
    Default = "",
    Placeholder = "Enter your name...",
    Numeric = false,
    Finished = false,
    MaxLength = 32,
    Callback = function(Text) end,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `string` | `""` | Initial text |
| `Placeholder` | `string` | `""` | Placeholder text |
| `Numeric` | `boolean` | `false` | Only allow numbers |
| `Finished` | `boolean` | `false` | Only fire callback on Enter |
| `MaxLength` | `number` | `nil` | Maximum character count |

**Methods**

```lua
Input:SetValue("Hello")
Input:OnChanged(function(Text) end)
Input:Destroy()
```

### Paragraph

```lua
Section:AddParagraph({
    Title = "Information",
    Content = "This is a paragraph of <b>rich</b> text.",
})
```

> Paragraphs support Roblox rich text if `RichText = true` is set on the TextLabel — the library sets this automatically for descriptions and content fields where mark-up is used.

---

## Icons

`Ssamachi:GetIcon(Name)` resolves an asset id string ready for `ImageLabel.Image`:

```lua
Image = Ssamachi:GetIcon("home-20-filled")   -- named icon via Fluent provider
Image = Ssamachi:GetIcon(123456789)          -- → "rbxassetid://123456789"
Image = Ssamachi:GetIcon("rbxassetid://123") -- passes through
Image = Ssamachi:GetIcon("https://...")      -- passes through
```

Use directly when constructing custom UI:

```lua
local ImageLabel = Instance.new("ImageLabel")
ImageLabel.Image = Ssamachi:GetIcon("star-20-filled")
```

---

## Notifications

```lua
Ssamachi:Notify({
    Title = "Success",
    Content = "Script loaded successfully",
    SubContent = "All modules ready",
    Duration = 5,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | `"Title"` | Notification title |
| `Content` | `string` | `"Content"` | Main content text |
| `SubContent` | `string` | `""` | Secondary text |
| `Duration` | `number` | `nil` | Auto-dismiss time in seconds (omit to persist) |

---

## Dialogs

```lua
Window:Dialog({
    Title = "Confirm Action",
    Content = "Are you sure you want to continue?",
    Buttons = {
        { Title = "Yes", Callback = function() end },
        { Title = "No" },
    },
})
```

---

## Minimizer

```lua
Ssamachi:CreateMinimizer({
    Icon = "toggle-right-20-regular",
    Size = UDim2.fromOffset(36, 36),
    Position = UDim2.new(0, 300, 0, 20),
    Draggable = true,
    Corner = 14,
    Transparency = 0,
    Visible = true,
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Icon` | `string \| number` | `"toggle-right-20-regular"` | Button icon |
| `Size` | `UDim2` | `UDim2.fromOffset(36, 36)` | Button size |
| `Position` | `UDim2` | `UDim2.new(0, 300, 0, 20)` | Button position |
| `Draggable` | `boolean` | `false` | Allow dragging the button |
| `Corner` | `number` | `14` | Corner radius |
| `Transparency` | `number` | `0` | Background transparency |
| `Visible` | `boolean` | `true` | Initial visibility |

---

## Config Save / Load

### Manual

```lua
Ssamachi.SaveManager:SetFolder("MyHub")
Ssamachi.SaveManager:Save("config1")
Ssamachi.SaveManager:Load("config1")
```

### Auto-Save

Pass `AutoConfig` when creating a window:

```lua
local Window = Ssamachi:CreateWindow({
    Title = "My Hub",
    AutoConfig = "default",
})
```

Every element change triggers an immediate save. The load happens automatically once every element has been registered (safe even if you call `SaveManager:Load` before adding elements — it will queue and retry).

### Ignoring Indexes

```lua
Ssamachi.SaveManager:SetIgnoreIndexes({ 1, 2, 3 })
```

---

## Notes

- **Search** is built into every window and cannot be disabled.
- **Rich text** — all labels, titles, and descriptions support Roblox rich text tags (`<b>`, `<i>`, `<font color="#...">`, etc.) — set `RichText = true` on any element config to enable mark-up in your text.
- **One window per script** — the library supports a single window at a time.
