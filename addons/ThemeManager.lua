local httpService = game:GetService('HttpService')

local ThemeManager = {}
ThemeManager.Folder = 'LinoriaLibSettings'
ThemeManager.Library = nil

ThemeManager.BuiltInThemes = {
    ['Default']      = { 1,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"a33b43","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
    ['UE']           = { 2,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"181818","AccentColor":"4777b6","BackgroundColor":"141414","OutlineColor":"1f1f1f"}') },
    ['Primordial']   = { 3,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"181818","AccentColor":"d7a6b0","BackgroundColor":"1f1f1f","OutlineColor":"2a2a2a"}') },
    ['BBot']         = { 4,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
    ['Fatality']     = { 5,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
    ['Jester']       = { 6,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
    ['Mint']         = { 7,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
    ['Tokyo Night']  = { 8,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
    ['Ubuntu']       = { 9,  httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
    ['Quartz']       = { 10, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
}

local THEME_FIELDS = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }

function ThemeManager:BuildFolderTree()
    local parts = self.Folder:split('/')
    local paths = {}
    for idx = 1, #parts do
        paths[#paths + 1] = table.concat(parts, '/', 1, idx)
    end
    paths[#paths + 1] = self.Folder .. '/themes'
    paths[#paths + 1] = self.Folder .. '/settings'

    for _, str in ipairs(paths) do
        if not isfolder(str) then
            makefolder(str)
        end
    end
end

function ThemeManager:SetFolder(folder)
    self.Folder = folder
    self:BuildFolderTree()
end

function ThemeManager:SetLibrary(lib)
    self.Library = lib
end

function ThemeManager:ApplyTheme(theme)
    local custom = self:GetCustomTheme(theme)
    local data = custom or self.BuiltInThemes[theme]
    if not data then return end

    local scheme = custom or data[2]
    for idx, col in next, scheme do
        self.Library[idx] = Color3.fromHex(col)
        if Options and Options[idx] then
            Options[idx]:SetValueRGB(Color3.fromHex(col))
        end
    end

    self:ThemeUpdate()
end

function ThemeManager:ThemeUpdate()
    for _, field in ipairs(THEME_FIELDS) do
        if Options and Options[field] then
            self.Library[field] = Options[field].Value
        end
    end

    self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
    self.Library:UpdateColorsUsingRegistry()
end

function ThemeManager:LoadDefault()
    local theme = 'Default'
    local path = self.Folder .. '/themes/default.txt'

    if isfile(path) then
        local content = readfile(path)
        if self.BuiltInThemes[content] or self:GetCustomTheme(content) then
            theme = content
        end
    elseif self.DefaultTheme and self.BuiltInThemes[self.DefaultTheme] then
        theme = self.DefaultTheme
    end

    Options.ThemeManager_ThemeList:SetValue(theme)
    self:ApplyTheme(theme)
end

function ThemeManager:SaveDefault(theme)
    writefile(self.Folder .. '/themes/default.txt', theme)
end

function ThemeManager:ClearDefaultIf(theme)
    local path = self.Folder .. '/themes/default.txt'
    if isfile(path) and readfile(path) == theme then
        delfile(path)
    end
end

function ThemeManager:GetCustomTheme(file)
    local path = self.Folder .. '/themes/' .. file .. '.json'
    if not isfile(path) then return nil end

    local success, decoded = pcall(httpService.JSONDecode, httpService, readfile(path))
    if not success or type(decoded) ~= 'table' then return nil end
    return decoded
end

function ThemeManager:SaveCustomTheme(file)
    if type(file) ~= 'string' or file:gsub(' ', '') == '' then
        return false, 'invalid theme name'
    end

    local theme = {}
    for _, field in ipairs(THEME_FIELDS) do
        theme[field] = Options[field].Value:ToHex()
    end

    writefile(self.Folder .. '/themes/' .. file .. '.json', httpService:JSONEncode(theme))
    return true
end

function ThemeManager:ReloadCustomThemes()
    local list = listfiles(self.Folder .. '/themes')
    local out = {}

    for _, file in ipairs(list) do
        if file:sub(-5) == '.json' then
            local pos = file:find('.json', 1, true)
            local char = file:sub(pos, pos)
            while char ~= '/' and char ~= '\\' and char ~= '' do
                pos = pos - 1
                char = file:sub(pos, pos)
            end
            if char == '/' or char == '\\' then
                table.insert(out, file:sub(pos + 1, file:find('.json', 1, true) - 1))
            end
        end
    end

    table.sort(out)
    return out
end

function ThemeManager:CreateThemeManager(container)
    container:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
    container:AddLabel('Main color')      :AddColorPicker('MainColor',      { Default = self.Library.MainColor })
    container:AddLabel('Accent color')    :AddColorPicker('AccentColor',    { Default = self.Library.AccentColor })
    container:AddLabel('Outline color')   :AddColorPicker('OutlineColor',   { Default = self.Library.OutlineColor })
    container:AddLabel('Text color')      :AddColorPicker('FontColor',      { Default = self.Library.FontColor })

    local ThemesArray = {}
    for name in next, self.BuiltInThemes do
        table.insert(ThemesArray, name)
    end
    table.sort(ThemesArray, function(a, b)
        return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1]
    end)

    container:AddDropdown('ThemeManager_ThemeList', {
        Text = 'Theme list',
        Values = ThemesArray,
        Default = 1
    })

    Options.ThemeManager_ThemeList:OnChanged(function()
        self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
    end)

    
    container:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })

    -- Create Theme
    container:AddButton('Create theme', function()
        local name = Options.ThemeManager_CustomThemeName.Value
        if type(name) ~= 'string' or name:gsub(' ', '') == '' then
            return self.Library:Notify('Invalid theme name (empty)', 2)
        end
        local ok, err = self:SaveCustomTheme(name)
        if not ok then
            return self.Library:Notify('Failed to save theme: ' .. err, 2)
        end
        self.Library:Notify(string.format('Saved theme %q', name))
        Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        Options.ThemeManager_CustomThemeList:SetValue(name)
    end)

    container:AddDropdown('ThemeManager_CustomThemeList', {
        Text = 'Custom themes',
        Values = self:ReloadCustomThemes(),
        AllowNull = true,
        Default = 1
    })

    -- Load theme
    container:AddButton('Load theme', function()
        local name = Options.ThemeManager_CustomThemeList.Value
        if not name then
            return self.Library:Notify('No custom theme selected', 2)
        end
        self:ApplyTheme(name)
    end)

    -- Overwrite + Delete
    container:AddButton('Overwrite Theme', function()
        local name = Options.ThemeManager_CustomThemeList.Value
        if not name then
            return self.Library:Notify('No custom theme selected', 2)
        end
        local ok, err = self:SaveCustomTheme(name)
        if not ok then
            return self.Library:Notify('Failed to overwrite theme: ' .. err, 2)
        end
        self.Library:Notify(string.format('Overwrote theme %q', name))
        Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        Options.ThemeManager_CustomThemeList:SetValue(name)
    end):AddButton('Delete Theme', function()
        local name = Options.ThemeManager_CustomThemeList.Value
        if not name then
            return self.Library:Notify('No custom theme selected', 2)
        end

        local path = self.Folder .. '/themes/' .. name .. '.json'
        if isfile(path) then
            delfile(path)
            self.Library:Notify(string.format('Deleted theme %q', name))
        else
            self.Library:Notify('Theme file not found', 2)
        end

        self:ClearDefaultIf(name)
        Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)

    -- Set Default + Reset Default
    container:AddButton('Set Default', function()
        local custom = Options.ThemeManager_CustomThemeList.Value
        local builtin = Options.ThemeManager_ThemeList.Value
        local name = custom or builtin
        if not name then
            return self.Library:Notify('No theme selected', 2)
        end
        self:SaveDefault(name)
        self.Library:Notify(string.format('Set default theme to %q', name))
    end):AddButton('Reset Default', function()
        self:ClearDefaultIf(readfile(self.Folder .. '/themes/default.txt') or '')
        Options.ThemeManager_ThemeList:SetValue('Default')
        self:ApplyTheme('Default')
        self.Library:Notify('Reset default theme to "Default"')
    end)

    -- Refresh
    container:AddButton('Refresh', function()
        Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
        Options.ThemeManager_CustomThemeList:SetValue(nil)
    end)

    self:LoadDefault()

    local function UpdateTheme()
        self:ThemeUpdate()
    end
    Options.BackgroundColor:OnChanged(UpdateTheme)
    Options.MainColor:OnChanged(UpdateTheme)
    Options.AccentColor:OnChanged(UpdateTheme)
    Options.OutlineColor:OnChanged(UpdateTheme)
    Options.FontColor:OnChanged(UpdateTheme)
end

function ThemeManager:CreateGroupBox(tab)
    assert(self.Library, 'Must set ThemeManager.Library first!')
    return tab:AddLeftTabbox() 
end

function ThemeManager:ApplyToTab(tab)
    assert(self.Library, 'Must set ThemeManager.Library first!')
    local tabbox = self:CreateGroupBox(tab)
    local themeTab = tabbox:AddTab('Themes')
    self:CreateThemeManager(themeTab)
end

function ThemeManager:ApplyToGroupbox(groupbox)
    assert(self.Library, 'Must set ThemeManager.Library first!')
    self:CreateThemeManager(groupbox)
end

ThemeManager:BuildFolderTree()

return ThemeManager
