# Ssamachi UI Library

A clean, modern Roblox UI library with smooth animations, built-in search, built-in minimizer, config saving, and rich element support.

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
    Minimizer = true, -- New
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Window title shown in the title bar |
| `SubTitle` | `string` | `nil` | Secondary text next to the title |
| `Icon` | `string \| number` | `nil` | Title bar icon (see [Icons](#icons)) |
| `Image` | `string` | `nil` | Large image displayed above the sidebar tabs. Also used as the minimizer icon if enabled. |
| `Size` | `UDim2` | `nil` | Initial window size |
| `TabWidth` | `number` | `nil` | Sidebar width in pixels |
| `MinimizeKey` | `Enum.KeyCode` | `LeftControl` | Key to hide/show the UI |
| `AutoConfig` | `string` | `nil` | Enables automatic config saving with this name |
| `Minimizer` | `boolean` | `true` (Mobile) / `true` (PC) | Toggles the built-in floating minimizer button. On Mobile, this is always `true`. |

> **Search is always enabled** — no configuration required.  
> Only **one window** can be created per script.

### Built-in Minimizer

The minimizer is automatically created when the window is opened. It is a floating, draggable `40x40` button positioned at the top-right corner of the screen.
- Its icon is automatically set to the `Image` specified in `CreateWindow`. If no `Image` is provided, no icon is shown.
- Dragging is always enabled.
- Clicking it minimizes/restores the main window.
- You no longer need to call `Ssamachi:CreateMinimizer()` manually.

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

---

## SubTabs

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

When a SubTab exists, `Tab:AddSection(...)` automatically routes to the currently selected SubTab.

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

Sections can also be added to a SubTab via `SubTab:AddSection(...)`.

---

## Elements

Every element accepts these **common** arguments unless noted otherwise:

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Element title |
| `Description` | `string` | `nil` | Secondary description |
| `Icon` | `string \| number` | `nil` | Element icon |

The first argument to every `Add*` method is a **unique numeric index** used by the config system. Pick any unique number per element.

---

### Button

```lua
Section:AddButton(1, {
    Title = "Click Me",
    Description = "Does something cool",
    Icon = "cursor-click-20-filled",
    Callback = function()
        print("clicked")
    end,
})
```

---

### Toggle

```lua
local Toggle = Section:AddToggle(2, {
    Title = "Enabled",
    Description = "Turn it on or off",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

**Methods**

```lua
Toggle:SetValue(true)
Toggle:OnChanged(function(Value) end)
Toggle:Destroy()
```

---

### Slider

```lua
local Slider = Section:AddSlider(3, {
    Title = "Speed",
    Default = 16,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value) end,
})
```

**Methods**

```lua
Slider:SetValue(50)
Slider:OnChanged(function(Value) end)
Slider:Destroy()
```

---

### Dropdown

```lua
local Dropdown = Section:AddDropdown(4, {
    Title = "Mode",
    Values = { "One", "Two", "Three" },
    Default = "One",
    Multi = false,
    AllowNull = false,
    KeepSearch = false,
    Callback = function(Value) end,
})
```

**Methods**

```lua
Dropdown:SetValue("Two")
Dropdown:SetValues({ "A", "B", "C" })
Dropdown:GetActiveValues()
Dropdown:OnChanged(function(Value) end)
Dropdown:Destroy()
```

---

### Keybind

```lua
local Keybind = Section:AddKeybind(5, {
    Title = "Aim Key",
    Default = "E",
    Mode = "Toggle",
    Callback = function(State) end,
    ChangedCallback = function(NewKey) end,
})
```

| Mode | Description |
|------|-------------|
| `Toggle` | Toggles state on key press |
| `Hold` | State is `true` while key is held |
| `Always` | Always returns `true` |

**Methods**

```lua
Keybind:GetState()
Keybind:SetValue("F", "Hold")
Keybind:OnChanged(function(Key) end)
Keybind:OnClick(function(State) end)
Keybind:Destroy()
```

---

### Colorpicker

```lua
local Picker = Section:AddColorpicker(6, {
    Title = "Accent Color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = true,
    Callback = function(Color) end,
})
```

**Methods**

```lua
Picker:SetValueRGB(Color3.fromRGB(0, 255, 0), 0.5)
Picker:SetValue({ 0.5, 1, 1 }, 0)  -- HSV + transparency
Picker:OnChanged(function(Color) end)
Picker:Destroy()
```

---

### Input

```lua
local Input = Section:AddInput(7, {
    Title = "Name",
    Default = "",
    Placeholder = "Enter your name...",
    Numeric = false,
    Finished = false,
    MaxLength = 32,
    Callback = function(Text) end,
})
```

**Methods**

```lua
Input:SetValue("Hello")
Input:OnChanged(function(Text) end)
Input:Destroy()
```

---

### Paragraph

```lua
Section:AddParagraph(8, {
    Title = "Information",
    Content = "This is a paragraph of <b>rich</b> text.",
})
```

---

## Icons

`Ssamachi:GetIcon(Name)` resolves a named icon to a **spritesheet URL string**:
`Ssamachi:ApplyIcon(Instance, Name)` applies the full icon (image + rect slicing) to an existing `ImageLabel`.

| Input Type | Resolution |
|------------|------------|
| `number` | `rbxassetid://<number>` |
| `"rbxassetid://..."` / `"https://..."` | passed through as-is |
| any other `string` | resolved via the Fluent icon provider |

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

## Config Save / Load

### Manual

```lua
Ssamachi.SaveManager:SetFolder("MyHub")
Ssamachi.SaveManager:Save("config1")
Ssamachi.SaveManager:Load("config1")
```

### Auto-Save

Pass `AutoConfig` when creating a window. Every element change instantly triggers an autosave, and loading is deferred until all elements are registered.

```lua
local Window = Ssamachi:CreateWindow({
    Title = "My Hub",
    AutoConfig = "default",
})
```

### Ignoring Indexes

```lua
Ssamachi.SaveManager:SetIgnoreIndexes({ 1, 2, 3 })
```
