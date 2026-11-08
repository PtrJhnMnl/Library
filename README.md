# Ssamachi UI Library

A clean, modern Roblox UI library with smooth animations, built-in search, built-in minimizer, config saving, and rich element support.

## Installation

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/PtrJhnMnl/Library/refs/heads/main/Ssamachi.lua"))()
```

## Creating a Window

```lua
local Window = Ssamachi:CreateWindow({
    Title = "My Hub",
    ConfigName = "myconfig",
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
| `ConfigName` | `string` | `nil` | Enables automatic config saving with this name |
| `Minimizer` | `boolean` | `false` (PC) / `true` (Mobile) | Toggles the built-in floating minimizer button. On Mobile, this is always `true`. |

## Built-in Minimizer

The minimizer is automatically created when the window is opened. It is a floating, draggable `50x50` button positioned at the top-right corner of the screen.

- Its icon is automatically set to the `Image` specified in `CreateWindow`. If no `Image` is provided, no icon is shown.
- Dragging is always enabled, and dragging will not accidentally click the button.
- Clicking it minimizes/restores the main window.
- You no longer need to call `Ssamachi:CreateMinimizer()` manually.

## Tabs

```lua
local Tab = Window:AddTab({
    Title = "Main",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Tab display name |
| `Icon` | `string \| number` | `nil` | Tab icon |

### Selecting a Tab Programmatically

```lua
Window:SelectTab(Tab)
Window:SelectTab("Main")
```

## SubTabs

```lua
local SubTab = Tab:AddSubTab({
    Title = "Aimbot",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | SubTab display name |
| `Icon` | `string \| number` | `nil` | SubTab icon |

When a SubTab exists, `Tab:AddSection(...)` automatically routes to the currently selected SubTab.

## Sections

```lua
local Section = Tab:AddSection({
    Title = "Combat",
})
```

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Section header text |
| `Icon` | `string \| number` | `nil` | Section icon |

Sections can also be added to a SubTab via `SubTab:AddSection(...)`.

## Elements

Every element accepts these **common** arguments unless noted otherwise:

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Element title |
| `Description` | `string` | `nil` | Secondary description |
| `Icon` | `string \| number` | `nil` | Element icon |

The first argument to every `Add*` method is a **unique string index** used by the config system. Pick any unique string per element.

### Button

```lua
Section:AddButton("ClickMe", {
    Title = "Click Me",
    Callback = function(Value)
        print("clicked")
    end,
})
```

### Toggle

```lua
local Toggle = Section:AddToggle("ToggleKey", {
    Title = "Enabled",
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

### Slider

```lua
local Slider = Section:AddSlider("SliderKey", {
    Title = "Speed",
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

### Dropdown

```lua
local Dropdown = Section:AddDropdown("DropdownKey", {
    Title = "Mode",
    Values = { "One", "Two", "Three" },
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

### Keybind

```lua
local Keybind = Section:AddKeybind("KeybindKey", {
    Title = "Aim Key",
    Default = "E",
    Callback = function(Value) end,
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
Keybind:OnChanged(function(Value) end)
Keybind:OnClick(function(Value) end)
Keybind:Destroy()
```

### Colorpicker

```lua
local Picker = Section:AddColorpicker("ColorKey", {
    Title = "Accent Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value) end,
})
```

**Methods**

```lua
Picker:SetValueRGB(Color3.fromRGB(0, 255, 0), 0.5)
Picker:SetValue({ 0.5, 1, 1 }, 0)
Picker:OnChanged(function(Value) end)
Picker:Destroy()
```

### Input

```lua
local Input = Section:AddInput("InputKey", {
    Title = "Name",
    Callback = function(Value) end,
})
```

**Methods**

```lua
Input:SetValue("Hello")
Input:OnChanged(function(Value) end)
Input:Destroy()
```

### Paragraph

```lua
Section:AddParagraph("ParagraphKey", {
    Title = "Information",
    Content = "This is a paragraph of <b>rich</b> text.",
})
```

## Icons

The library now uses the **Lucide** icon set as its default provider.

- Named icons (e.g. `"mouse-pointer-click"`, `"chevron-down"`, `"search"`, `"circle-letter-o"`) are resolved via `Ssamachi:GetIcon(Name)` and can be applied with `Ssamachi:ApplyIcon(Instance, Name)`.
- Numeric icon IDs are converted to `rbxassetid://<number>`.
- Strings starting with `rbxasset` or `http` are passed through as-is.

Browse all available Lucide icons at: [https://molto.pages.dev/icons/#lucide](https://molto.pages.dev/icons/#lucide)

| Input Type | Resolution |
|------------|------------|
| `number` | `rbxassetid://<number>` |
| `"rbxassetid://..."` / `"https://..."` | passed through as-is |
| any other `string` | resolved via the Lucide icon provider |

## Notifications

```lua
Ssamachi:Notify({
    Title = "Success",
    Content = "Script loaded successfully",
    Duration = 5,
})
```

## Dialogs

```lua
Window:Dialog({
    Title = "Confirm Action",
    Content = "Are you sure you want to continue?",
    Buttons = {
        { Title = "Yes", Callback = function(Value) end },
        { Title = "No" },
    },
})
```

## Config Save / Load

### Manual

```lua
Ssamachi.SaveManager:SetFolder("MyHub")
Ssamachi.SaveManager:Save("config1")
Ssamachi.SaveManager:Load("config1")
```

### Auto-Save

Pass `ConfigName` when creating a window. Every element change instantly triggers an autosave, and loading is deferred until all elements are registered.

```lua
local Window = Ssamachi:CreateWindow({
    Title = "My Hub",
    ConfigName = "default",
})
```

### Ignoring Indexes

```lua
Ssamachi.SaveManager:SetIgnoreIndexes({ "ToggleKey", "SliderKey" })
```
