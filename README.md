## Installation

```lua
local Ssamachi = loadstring(game:HttpGet("https://raw.githubusercontent.com/PtrJhnMnl/Library/refs/heads/main/Ssamachi.lua"))()
```

## API Reference

### `Ssamachi:CreateWindow(Config)`

**Example**

```lua
local Window = Ssamachi:CreateWindow({ Title = "Ssamachi" })
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `SubTitle` | string | `nil` | No |
| `Icon` | string / number | `nil` | No |
| `Image` | string / number | `nil` | No |
| `Size` | UDim2 | `UDim2.fromOffset(600, 480)` | No |
| `TabWidth` | number | `160` | No |
| `ConfigName` | string | `nil` | No |
| `MinimizeKey` | Enum.KeyCode | `Enum.KeyCode.LeftControl` | No |
| `Minimizer` | boolean | `false` | No |

Returns: `Window`

---

### `Window:AddTab(Config)`

**Example**

```lua
local Tab = Window:AddTab({ Title = "Main" })
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Tab`

---

### `Window:SelectTab(Index)`

**Example**

```lua
Window:SelectTab(1)
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Index` | number | `nil` | Yes |

---

### `Tab:AddSection(Title, Icon)`

**Example**

```lua
local Section = Tab:AddSection("General")
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Icon` | string / number | `nil` | No |

Returns: `Section`

---

### Elements

All elements accept `(Idx, Config)` where `Idx` is a unique string identifier used for saving/loading. `Button` and `Paragraph` are the only elements that do not require an `Idx`.

Shared element methods available where applicable:

- `SetTitle(string)`
- `SetDesc(string)`
- `Visible(boolean)`
- `Destroy()`

---

#### `Section:AddButton(Config)`

**Example**

```lua
Section:AddButton({
    Title = "Click Me",
    Callback = function()
        print("Clicked")
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Icon` | string / number | `nil` | No |
| `Callback` | function | `function() end` | No |

Returns: `Button`

Note: Buttons are not saved or loaded by the config system and do not require an `Idx`.

---

#### `Section:AddToggle(Idx, Config)`

**Example**

```lua
Section:AddToggle("MyToggle", {
    Title = "Toggle",
    Callback = function(Value)
        print("Toggle:", Value)
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | boolean | `false` | No |
| `Callback` | function | `function(Value) end` | No |

Returns: `Toggle`

Element methods:

- `SetValue(boolean)`
- `OnChanged(function)`

---

#### `Section:AddSlider(Idx, Config)`

**Example**

```lua
Section:AddSlider("MySlider", {
    Title = "Slider",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(Value)
        print("Slider:", Value)
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | number | `nil` | Yes |
| `Min` | number | `nil` | Yes |
| `Max` | number | `nil` | Yes |
| `Rounding` | number | `nil` | Yes |
| `Callback` | function | `function(Value) end` | No |

Returns: `Slider`

Element methods:

- `SetValue(number)`
- `OnChanged(function)`

---

#### `Section:AddDropdown(Idx, Config)`

**Example**

```lua
Section:AddDropdown("MyDropdown", {
    Title = "Dropdown",
    Values = { "One", "Two", "Three" },
    Callback = function(Value)
        print("Dropdown:", Value)
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Values` | table | `nil` | Yes |
| `Default` | string / table | `nil` | No |
| `Multi` | boolean | `false` | No |
| `AllowNull` | boolean | `false` | No |
| `KeepSearch` | boolean | `false` | No |
| `Callback` | function | `function(Value) end` | No |

Returns: `Dropdown`

Element methods:

- `SetValue(string / table)`
- `SetValues(table)`
- `OnChanged(function)`

---

#### `Section:AddKeybind(Idx, Config)`

**Example**

```lua
Section:AddKeybind("MyKeybind", {
    Title = "Keybind",
    Default = "E",
    Callback = function(Value)
        print("Keybind:", Value)
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | string | `nil` | Yes |
| `Mode` | string | `"Toggle"` | No |
| `Callback` | function | `function(Value) end` | No |
| `ChangedCallback` | function | `function(New) end` | No |

Returns: `Keybind`

Element methods:

- `SetValue(string, string)`
- `OnChanged(function)`
- `OnClick(function)`
- `GetState()`

---

#### `Section:AddColorpicker(Idx, Config)`

**Example**

```lua
Section:AddColorpicker("MyColor", {
    Title = "Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        print("Color:", Value)
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | Color3 | `nil` | Yes |
| `Transparency` | number | `0` | No |
| `Callback` | function | `function(Value) end` | No |

Returns: `Colorpicker`

Element methods:

- `SetValue(table, number)`
- `SetValueRGB(Color3, number)`
- `OnChanged(function)`

---

#### `Section:AddInput(Idx, Config)`

**Example**

```lua
Section:AddInput("MyInput", {
    Title = "Input",
    Callback = function(Value)
        print("Input:", Value)
    end
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Description` | string | `nil` | No |
| `Default` | string | `""` | No |
| `Placeholder` | string | `""` | No |
| `Numeric` | boolean | `false` | No |
| `Finished` | boolean | `false` | No |
| `MaxLength` | number | `nil` | No |
| `Callback` | function | `function(Value) end` | No |

Returns: `Input`

Element methods:

- `SetValue(string)`
- `OnChanged(function)`

---

#### `Section:AddParagraph(Config)`

**Example**

```lua
Section:AddParagraph({
    Title = "Info",
    Content = "This is a paragraph of text."
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Content` | string | `""` | No |
| `Icon` | string / number | `nil` | No |

Returns: `Paragraph`

Note: Paragraphs are not saved or loaded by the config system.

---

### `Window:Dialog(Config)`

**Example**

```lua
Window:Dialog({
    Title = "Confirm",
    Content = "Are you sure?",
    Buttons = {
        { Title = "Yes", Callback = function() print("yes") end },
        { Title = "No", Callback = function() print("no") end }
    }
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `nil` | Yes |
| `Content` | string | `nil` | Yes |
| `Buttons` | table | `{}` | No |
| `Buttons[].Title` | string | `nil` | Yes |
| `Buttons[].Line` | number | `1` | No |
| `Buttons[].Callback` | function | `function() end` | No |

Buttons sharing the same `Line` render side-by-side in one row. A single button on a line spans the full row width. Lines are sorted ascending.

---

### `Ssamachi:Notify(Config)`

**Example**

```lua
Ssamachi:Notify({
    Title = "Ssamachi",
    Content = "Loaded successfully"
})
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Title` | string | `"Title"` | No |
| `Content` | string | `"Content"` | No |
| `SubContent` | string | `""` | No |
| `Duration` | number | `nil` | No |

Returns: `Notification`

Notification methods:

- `Close()`

---

### `Ssamachi:SaveConfiguration(Name)`

**Example**

```lua
Ssamachi:SaveConfiguration()
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Name` | string | `Window.ConfigName` | No |

Returns: `boolean`

---

### `Ssamachi:LoadConfiguration(Name)`

**Example**

```lua
Ssamachi:LoadConfiguration()
```

**Parameter Table**

| Arg | Type | Default | Required |
|---|---|---|---|
| `Name` | string | `Window.ConfigName` | No |

Returns: `boolean`

---

### Element Ordering

Elements are ordered strictly by creation order. Each `Add*` call assigns an incrementing `LayoutOrder` internally, so the visual order always matches the code order. The same applies to `AddSection` and `AddTab`.

---

### Config Persistence

The following element types are saved and loaded automatically when a `ConfigName` is set:

- `Toggle`
- `Slider`
- `Dropdown`
- `Colorpicker`
- `Keybind`
- `Input`

The following element types are **not** saved:

- `Button`
- `Paragraph`

Config files are stored as JSON in the `Ssamachi` folder.

---

## License

MIT
