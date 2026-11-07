# Ssamachi UI Library

A clean, modern Roblox UI library with smooth animations, built-in search, config saving, and rich element support.

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/PtrJhnMnl/Library/refs/heads/main/Ssamachi.lua"))()
```

---

## Table of Contents

- [Creating a Window](#creating-a-window)
- [Tabs](#tabs)
- [SubTabs](#subtabs)
- [Sections](#sections)
- [Elements](#elements)
  - [Button](#button)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Keybind](#keybind)
  - [Colorpicker](#colorpicker)
  - [Input](#input)
  - [Paragraph](#paragraph)
- [Icons](#icons)
- [Notifications](#notifications)
- [Dialogs](#dialogs)
- [Minimizer](#minimizer)
- [Config Save / Load](#config-save--load)
- [Notes](#notes)

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
| `Image` | `string \| number` | `nil` | Large image displayed above the sidebar tabs |
| `Size` | `UDim2` | `nil` | Initial window size |
| `TabWidth` | `number` | `nil` | Sidebar width in pixels |
| `MinimizeKey` | `Enum.KeyCode` | `LeftControl` | Key to hide/show the UI |
| `AutoConfig` | `string` | `nil` | Enables automatic config saving with this name |

> **Search is always enabled** — no configuration required.  
> Only **one window** can be created per script.

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Callback` | `function` | `nil` | Called when the button is clicked |

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `boolean` | `false` | Initial value |
| `Callback` | `function` | `nil` | Called with the new boolean value |

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Values` | `table` | required | List of selectable options |
| `Default` | `string \| table` | `nil` | Initial selection (`table` for Multi) |
| `Multi` | `boolean` | `false` | Allow multiple selections |
| `AllowNull` | `boolean` | `false` | Allow deselecting all (Multi only) |
| `KeepSearch` | `boolean` | `false` | Preserve search text after closing |

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `string` | required | Initial key name (`"E"`, `"MouseRight"`, ...) |
| `Mode` | `string` | `"Toggle"` | `"Toggle"`, `"Hold"`, or `"Always"` |
| `ChangedCallback` | `function` | `nil` | Called when the key binding changes |

**Modes**

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Default` | `string` | `""` | Initial text |
| `Placeholder` | `string` | `""` | Placeholder text |
| `Numeric` | `boolean` | `false` | Only allow numeric input |
| `Finished` | `boolean` | `false` | Only fire callback on Enter |
| `MaxLength` | `number` | `nil` | Maximum character count |

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Content` | `string` | `""` | Paragraph body (supports Roblox rich text) |

---

## Icons

`Ssamachi:GetIcon(Name)` resolves a named icon to a **spritesheet URL string** (useful for `Window.Image` or `Minimizer.Icon`):

```lua
Window.Image    = Ssamachi:GetIcon("home-20-filled")
Minimizer.Icon  = Ssamachi:GetIcon(123456789)   -- → "rbxassetid://123456789"
```

`Ssamachi:ApplyIcon(Instance, Name)` applies the full icon (image + rect slicing) to an existing `ImageLabel`:

```lua
local Label = Instance.new("ImageLabel")
Ssamachi:ApplyIcon(Label, "star-20-filled")
```

| Input Type | Resolution |
|------------|------------|
| `number` | `rbxassetid://<number>` |
| `"rbxassetid://..."` / `"https://..."` | passed through as-is |
| any other `string` | resolved via the Fluent icon provider |
| `nil` / empty | returns `nil` |

> Use `GetIcon` when you only need a URL (e.g. one non-sliced image).  
> Use `ApplyIcon` when you need the icon drawn correctly with sprite-sheet slicing.

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

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `Title` | `string` | required | Dialog header text |
| `Content` | `string` | required | Dialog body text |
| `Buttons` | `table` | required | Array of `{ Title, Callback }` button configs |

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
| `Corner` | `number` | `14` (desktop) / `12` (mobile) | Corner radius |
| `Transparency` | `number` | `0` | Background transparency (0–1) |
| `Visible` | `boolean` | `true` | Initial visibility |

Clicking the minimizer toggles the window's visibility.

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

- Every element change **instantly** triggers an autosave (no debounce delay applied to the write).
- Load is **deferred** until every element has been registered — even if `SaveManager:Load` is called early, it will queue and retry automatically until `Library.ElementsReady` becomes `true`.

### Ignoring Indexes

Exclude specific element indexes from save/load:

```lua
Ssamachi.SaveManager:SetIgnoreIndexes({ 1, 2, 3 })
```

### API

| Method | Description |
|--------|-------------|
| `SaveManager:SetFolder(folder)` | Sets the save folder (creates it if missing) |
| `SaveManager:Save(name)` | Saves current options to `<folder>/<name>.json` |
| `SaveManager:Load(name)` | Loads `<folder>/<name>.json` — retries until elements are ready |
| `SaveManager:SetIgnoreIndexes(list)` | Skips listed element indexes on save/load |
| `SaveManager:SetLibrary(library)` | Binds the library instance (done automatically via `CreateWindow`) |

---

## Notes

- **Search** is built into every window and cannot be disabled.
- **Rich text** is supported on all labels, titles, descriptions, and content fields — set `RichText = true` on any element config if you want tags like `<b>`, `<i>`, `<font color="#...">` to render. The library also passes `RichText = true` for Toggle / Button titles automatically.
- **One window per script** — the library supports a single window at a time.
- **Theme** is fixed to `"Darker"` — `Library:SetTheme()` is exposed for compatibility but currently only supports that one theme.
