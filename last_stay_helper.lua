script_name("last_stay_helper")
script_author("NoPressF")
script_url("https://github.com/NoPressF/last_stay_helper")
script_version("V1.0")

local enable_autoupdate = true
local autoupdate_loaded = false
local Update = nil
local update = false

-- Load Inicfg

local inicfg = require('inicfg')

local path_last_stay_helper = 'last_stay_helper.ini'

local main_ini = inicfg.load({
	items_categories =
	{
		dry_food = true,
		fry_meat = true,
		raw_meat = true,
		pizza = true,
		burger = true,
		apple = true,
		can_of_beans = true,
		semi_fished_products = true,
		bottle = true,
		sprunk = true,
		apple_juice = true,
		orange_juice = true,
		milk = true,

		crowbar = true,
		fuelcan = true,
		spare_parts = true,
		battery = true,
		wheel = true,
		chainsaw = true,

		code_lock = true,
		red_fire = true,
		storage = true
	},
	settings = 
	{
		draw_distance_items = MAX_DRAW_DISTANCE_ITEMS,
		draw_font_size = MIN_DRAW_FONT_SIZE,
		draw_font_color = DEFAULT_FONT_COLOR,
		draw_items = true
	},
	update =
	{	
		updated_script = false
	}
}, path_last_stay_helper)

render_font_size = main_ini.settings.draw_font_size

if not doesFileExist('moonloader/config/'..path_last_stay_helper) then 
	inicfg.save(main_ini, path_last_stay_helper)
else
	inicfg.save(main_ini, path_last_stay_helper)
end

local have_update = main_ini.update.updated_script

if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[
    return {
		check = function(a, b, c)
		    local d = require('moonloader').download_status
		    local e = os.tmpname()
		    local f = os.clock()
		    
		    if doesFileExist(e) then
		        os.remove(e)
		    end

		    downloadUrlToFile(a, e, function(g, h, i, j)
		        if h == d.STATUSEX_ENDDOWNLOAD then
		            if doesFileExist(e) then
		                local k = io.open(e, 'r')
		                if k then
		                    local l = decodeJson(k:read('*a'))
		                    updatelink = l.updateurl
		                    updateversion = l.latest
		                    k:close()
		                    os.remove(e)
		                    
		                    if updateversion ~= thisScript().version then
		                        lua_thread.create(function(b)
		                            local d = require('moonloader').download_status
		                            local m = -1
		                            sampAddChatMessage(b..'Обнаружено обновление. Скачиваем обновление '..updateversion, m)
		                            update = true
		                            wait(250)
		                            downloadUrlToFile(updatelink, thisScript().path, function(n, o, p, q)
		                                if o == d.STATUS_ENDDOWNLOADDATA then
		                                    sampAddChatMessage(b..'Обновление скрипта успешно завершено!', m)
		                                    goupdatestatus = true
		                                    have_update = true
		                                    main_ini.update.have_update = true
		                                    inicfg.save(main_ini, path_last_stay_helper)
		                                    lua_thread.create(function()
		                                        wait(500)
		                                        thisScript():reload()
		                                    end)
		                                end
		                                if o == d.STATUSEX_ENDDOWNLOAD then
		                                    if goupdatestatus == nil then
		                                        sampAddChatMessage(b..'Не удалось обновить скрипта на версию скрипта '..updateversion..'. Запускаем старую версию скрипта!', m)
		                                        update = false
		                                    end
		                                end
		                            end)
		                        end, b)
		                    else
		                    	print("обновления не требуются")
		                        update = false
		                        if l.telemetry then
		                            local r = require"ffi"
		                            r.cdef "int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"
		                            local s = r.new("unsigned long[1]", 0)
		                            r.C.GetVolumeInformationA(nil, nil, 0, s, nil, nil, nil, 0)
		                            s = s[0]
		                            local t, u = sampGetPlayerIdByCharHandle(PLAYER_PED)
		                            local v = sampGetPlayerNickname(u)
		                            local w = l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())
		                            lua_thread.create(function(c)
		                                wait(250)
		                                downloadUrlToFile(c)
		                            end, w)
		                        end
		                    end
		                end
		            else
		                update = false
		            end
		        end
		    end)

		    while update ~= false and os.clock() - f < 10 do
		        wait(100)
		    end
		end
		}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then

            Update.json_url = "https://raw.githubusercontent.com/NoPressF/last_stay_helper/main/current_version.json?" .. tostring(os.clock())
            Update.prefix = "{FFFF55}[LastStayHelper]{FFFFFF} "
            Update.url = "https://github.com/NoPressF/last_stay_helper/"
        end
    end
end

require "lib.moonloader"
require "lib.sampfuncs"

font_name = 'Calibri'
font_size = 13
font_flags = 13

render_font_name = 'Arial'
render_font_size = 8
render_font_flags = 13

health_vehicle_font_name = 'Arial'
health_vehicle_font_size = 12
health_vehicle_font_flags = 13

local hook = require('lib.samp.events')
local imgui = require('imgui')
local key = require('vkeys')
local game_keys = require "game.keys"
local encoding = require('encoding')
encoding.default = 'CP1251'
u8 = encoding.UTF8

-- Count (Zombies, Players, Vehicles)

local zombiesNear = 0
local playersNear = 0

-- Arrays Data

local server_items = { 
	{ {2663, "Сухой паек", "dry_food"}, {19882, "Жареное мясо", "fry_meat"}, {19582, "Сырое мясо", "raw_meat"}, {2814, "Пицца", "pizza"}, {2768, "Бургер", "burger"}, {19576, "Яблоко", "apple"}, {1666, "Банка бобов", "can_of_beans"}, {19566, "Рыбные полуфабрикаты", "semi_fished_products"}, {1509, "Бутылка", "bottle"}, {1546, "Sprunk", "sprunk"}, {19564, "Яблочный сок", "apple_juice"}, {19563, "Апельсиновый сок", "orange_juice"}, {2856, "Молоко", "milk"} }, 
	{ {18634, "Лом", "crowbar"}, {1650, "Канистра", "fuelcan"}, {3013, "Запчасти", "spare_parts"}, {19918, "Аккумулятор", "battery"}, {1074, "Колесо", "wheel"}, {341, "Бензопила", "chainsaw"} },
	{ {2922, "Кодовый замок", "code_lock"}, {1672, "Красный фаер", "red_fire"}, {1279, "Хранилище", "storage"} } 
}

--local reasons = {"Кулак", "Кастет", "Клюшка для гольфа", "Полицейская дубинка", "Нож", "Бейсбольная бита", "Лопата", "Кий", "Кий", "Катана", "Бензопила", "Большой дилдо", "Малый дилдо", "Большой вибратор", "Малый вибратор", "Цветы", "Трость", "Граната", "Слезоточивый газ", "Коктейль молотова", "Colt .45", "Colt .45 (глушитель)", "Desert Eagle", "Shotgun", "Sawed Off", "Combat Shotgun", "Uzi", "MP5", "AK-47", "M4", "Tec-9", "Country Rifle", "Sniper Rifle", "RPG", "RPG (HeatSeeker)", "Flamethrower", "Minigun", "Satchel", "Detonator", "SprayCan", "Vehicle"}

-- Constants

local MIN_DRAW_DISTANCE_ITEMS = 10
local MAX_DRAW_DISTANCE_ITEMS = 70

local MIN_DRAW_FONT_SIZE = 8
local MAX_DRAW_FONT_SIZE = 15

local DEFAULT_FONT_COLOR = 0xFFFFFF00

local DIALOG_USE_ITEM_ID = 100
local DIALOG_INVENTORY_ID =	187

-- Objects ImGUI

local distance_draw_items_slider = imgui.ImInt(main_ini.settings.draw_distance_items)
local slider_font_size = imgui.ImInt(main_ini.settings.draw_font_size)
local wallhack_items_check_box = imgui.ImBool(main_ini.settings.draw_items)

-- Arrays

local reset_draw_font_color = imgui.ImVec2(0.0, 0.0)

local toggle_items_data = { { }, { }, { } }

local total_enabled_items = {0, 0, 0}

local toggle_all_items = { }

local provision_index = 1
local mechanic_index = 2
local rare_items_index = 3

-- Data

local toggle_auto_crowbar_lambing = false
local finded_crowbar = false

local toggle_auto_fill_fuel_can = false
local finded_empty_fuel_can = false

local use_pain_killer = false

-- Main Window

local last_stay_helper_window = imgui.ImBool(false)

imgui.ShowCursor = last_stay_helper_window.v
imgui.Process = last_stay_helper_window.v

local render_font = renderCreateFont(render_font_name, render_font_size, render_font_flags)
local health_vehicle_font = renderCreateFont(health_vehicle_font_name, health_vehicle_font_size, health_vehicle_font_flags)

local color_number = main_ini.settings.draw_font_color

local color = imgui.ImFloat4(imgui.ImColor(bit.rshift(bit.band(color_number, 0xFF0000), 16), bit.rshift(bit.band(color_number, 0x00FF00), 8), bit.band(color_number, 0x0000FF), 255):GetFloat4())

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

    if have_update == false then

		if not sampIsLocalPlayerSpawned() then
			sampAddChatMessage("{FFFF55}[LastStayHelper]{FFFFFF} - Скрипт загружен!", -1)
		else
			sampAddChatMessage("{FFFF55}[LastStayHelper]{FFFFFF} - Скрипт перезагружен!", -1)
		end
	else
		have_update = false
	end

	for i = 1, #server_items do
		for x = 1, #server_items[i] do
			toggle_items_data[i][x] = imgui.ImBool(main_ini.items_categories[server_items[i][x][3]])

			if toggle_items_data[i][x].v == true then
				total_enabled_items[i] = total_enabled_items[i] + 1
			end

			if total_enabled_items[i] < #server_items[i] then
				toggle_all_items[i] = imgui.ImBool(false)
			else
				toggle_all_items[i] = imgui.ImBool(true)
			end
		end
	end

	local zombiesRenderDrawFont = renderCreateFont(font_name, font_size, font_flags)
	local playersRenderDrawFont = renderCreateFont(font_name, font_size, font_flags)
	local vehiclesRenderDrawFont = renderCreateFont(font_name, font_size, font_flags)

	while true do wait(0)

		-- Get near players and zombies

		for _, v in pairs(getAllChars()) do
			local result, playerid = sampGetPlayerIdByCharHandle(v)
			if result then
				if sampIsPlayerNpc(playerid) then
					if sampGetPlayerHealth(playerid) ~= 0 then
						zombiesNear = zombiesNear + 1
					end
				else
					playersNear = playersNear + 1
				end
			end
		end

		if isCharInAnyCar(playerPed) then
			local car_health = getCarHealth(storeCarCharIsInNoSave(playerPed))
			local health_procent = (getCarHealth(storeCarCharIsInNoSave(playerPed)) - 300) / ((1000 - 300) / 100)
			renderFontDrawText(health_vehicle_font, "Здоровье: "..math.floor(math.abs(health_procent)).." %", 1000, 555, -1)
		end

		-- Render near unique objects

		local x, y, z = getCharCoordinates(playerPed)

		if main_ini.settings.draw_items == true then

			for _, v in pairs(getAllObjects()) do

				local _, ox, oy, oz = getObjectCoordinates(v)

				if isPointOnScreen(ox, oy, oz, 0.0) then
					if oz ~= 0 then

						if getDistanceBetweenCoords3d(ox, oy, oz, x, y, z) < distance_draw_items_slider.v then

							for i = 1, #server_items do

								for x = 1, #server_items[i] do

									if toggle_items_data[i][x].v and server_items[i][x][1] == getObjectModel(v) then

										local ui_x, ui_y = convert3DCoordsToScreen(ox, oy, oz)

										renderFontDrawText(render_font, server_items[i][x][2], ui_x, ui_y, main_ini.settings.draw_font_color)
									end
								end
							end
						end
					end
				end
			end
		end

		renderFontDrawText(zombiesRenderDrawFont, "{32CD32}Zombies: "..zombiesNear, 30, 300, -1)
		renderFontDrawText(playersRenderDrawFont, "{FF2D2D}Players: "..playersNear - 1, 30, 320, -1)
		renderFontDrawText(vehiclesRenderDrawFont, "{466EFF}Vehicles: "..#getAllVehicles(), 30, 340, -1)
		zombiesNear = 0
		playersNear = 0

		if wasKeyPressed(key.VK_B) and not sampIsDialogActive() and not sampIsChatInputActive() then
			last_stay_helper_window.v = not last_stay_helper_window.v
			imgui.ShowCursor = last_stay_helper_window.v
		end

		if isKeyJustPressed(key.VK_L) and not sampIsDialogActive() and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
			toggle_auto_crowbar_lambing = not toggle_auto_crowbar_lambing

			sampAddChatMessage(toggle_auto_crowbar_lambing == true and "[Уведомление] {FFFFFF}Вы включили авто-добычу ломом!" or "[Уведомление] {FFFFFF}Вы выключили авто-добычу ломом!", 0xFFFFAA2A)
			
			if toggle_auto_crowbar_lambing == true then
				simulateKeyPress(key.VK_Y)
			end
		end

		if isKeyJustPressed(key.VK_K) and not sampIsDialogActive() and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
			toggle_auto_fill_fuel_can = not toggle_auto_fill_fuel_can

			sampAddChatMessage(toggle_auto_fill_fuel_can == true and "[Уведомление] {FFFFFF}Вы включили авто-заправку канистр!" or "[Уведомление] {FFFFFF}Вы выключили авто-заправку канистр!", 0xFFFFAA2A)
			
			if toggle_auto_fill_fuel_can == true then
				simulateKeyPress(key.VK_Y)
			end
		end

		if isKeyJustPressed(key.VK_N) then
			toggle_auto_crowbar_lambing = false
			toggle_auto_fill_fuel_can = false
		end

		if isKeyJustPressed(key.VK_0) and not sampIsDialogActive() and not sampIsChatInputActive() and not isSampfuncsConsoleActive() then
			use_pain_killer = true
			simulateKeyPress(key.VK_Y)
		end

		imgui.Process = last_stay_helper_window.v
	end
end

function getDistanceBetweenCoords3d(x1, y1, z1, x2, y2, z2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2) + math.pow(z1 - z2, 2))
end

-- ImGUI functions

function ImRGBToVec4(r, g, b, a)
	return (1.0 / 255) * r, (1.0 / 255) * g, (1.0 / 255) * b, (1.0 / 255) * a
end

function ApplyCustomStyle()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local color = imgui.Col
	local ImVec4 = imgui.ImVec4

	style.WindowRounding = 12.0
	style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	style.ChildWindowRounding = 2.0
	style.FrameRounding = 2.0
	style.ItemSpacing = imgui.ImVec2(2.0, 4.0)
	style.ScrollbarSize = 13.0
	style.ScrollbarRounding = 0
	style.GrabMinSize = 13.0
	style.GrabRounding = 2.0

	colors[color.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[color.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
	colors[color.WindowBg]             	 = ImVec4(ImRGBToVec4(5, 5, 5, 255))
	colors[color.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
	colors[color.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
	colors[color.ComboBg]                = colors[color.PopupBg]
	colors[color.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[color.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
	colors[color.FrameBg]                = ImVec4(ImRGBToVec4(199, 26, 26, 255))
	colors[color.FrameBgHovered]         = ImVec4(ImRGBToVec4(157, 20, 20, 255))
	colors[color.FrameBgActive]          = ImVec4(ImRGBToVec4(199, 26, 26, 255))
	colors[color.TitleBg]                = ImVec4(ImRGBToVec4(27, 27, 27, 255))
	colors[color.TitleBgActive]          = ImVec4(ImRGBToVec4(27, 27, 27, 255))
	colors[color.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
	colors[color.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
	colors[color.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
	colors[color.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
	colors[color.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
	colors[color.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
	colors[color.CheckMark]              = ImVec4(ImRGBToVec4(92, 12, 3, 255))
	colors[color.SliderGrab]             = ImVec4(ImRGBToVec4(110, 14, 14, 255))
	colors[color.SliderGrabActive]       = ImVec4(ImRGBToVec4(110, 14, 14, 255))
	colors[color.Button]                 = ImVec4(ImRGBToVec4(199, 26, 26, 255))
	colors[color.ButtonHovered]          = ImVec4(ImRGBToVec4(154, 20, 20, 255))
	colors[color.ButtonActive]           = ImVec4(ImRGBToVec4(199, 26, 26, 255))
	colors[color.Header]                 = ImVec4(ImRGBToVec4(199, 26, 26, 255))
	colors[color.HeaderHovered]          = ImVec4(ImRGBToVec4(154, 20, 20, 255))
	colors[color.HeaderActive]           = ImVec4(ImRGBToVec4(199, 26, 26, 255))
	colors[color.Separator]              = colors[color.Border]
	colors[color.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
	colors[color.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[color.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
	colors[color.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
	colors[color.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
	colors[color.CloseButton]            = ImVec4(ImRGBToVec4(20, 20, 20, 255))
	colors[color.CloseButtonHovered]     = ImVec4(ImRGBToVec4(15, 15, 15, 255))
	colors[color.CloseButtonActive]      = ImVec4(ImRGBToVec4(20, 20, 20, 255))
	colors[color.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[color.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[color.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[color.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
	colors[color.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
	colors[color.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end

ApplyCustomStyle()

function imgui.OnDrawFrame()

	if last_stay_helper_window.v then

		local sw, sh = getScreenResolution()

		imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(310, 280), imgui.Cond.FirstUseEver)

		imgui.Begin("Last Stay Helper", last_stay_helper_window, imgui.WindowFlags.NoResize)

		if imgui.CollapsingHeader(u8"Категории предметов") then
			if imgui.Checkbox(u8"Прорисовка предметов", wallhack_items_check_box) then
				main_ini.settings.draw_items = wallhack_items_check_box.v
				inicfg.save(main_ini, path_last_stay_helper)
			end

			imgui.Separator()

			if imgui.CollapsingHeader(u8"Провизия") then
				ProcessAllItemsCheckbox(provision_index)
				ProcessItemCheckbox(provision_index)
			end

			imgui.Separator()

			if imgui.CollapsingHeader(u8"Механика") then
				ProcessAllItemsCheckbox(mechanic_index)
				ProcessItemCheckbox(mechanic_index)
			end

			imgui.Separator()

			if imgui.CollapsingHeader(u8"Редкие предметы") then
				ProcessAllItemsCheckbox(rare_items_index)
				ProcessItemCheckbox(rare_items_index)
			end

			imgui.Separator()
		end

		if imgui.CollapsingHeader(u8"Настройки") then

			imgui.Text(u8"Дистанция прорисовки предметов")
			if imgui.SliderInt("", distance_draw_items_slider, MIN_DRAW_DISTANCE_ITEMS, MAX_DRAW_DISTANCE_ITEMS) then
				main_ini.settings.draw_distance_items = distance_draw_items_slider.v
				inicfg.save(main_ini, path_last_stay_helper)
			end

			imgui.Text(u8"Размер шрифта предмета")
			if imgui.SliderInt(" ", slider_font_size, MIN_DRAW_FONT_SIZE, MAX_DRAW_FONT_SIZE) then
				render_font = renderCreateFont(render_font_name, slider_font_size.v, render_font_flags)
				main_ini.settings.draw_font_size = slider_font_size.v
				inicfg.save(main_ini, path_last_stay_helper)
			end

			imgui.Text(u8"Цвет шрифта")
			if imgui.ColorEdit4("", color) then
	            local select_color = join_argb(color.v[4] * 255, color.v[1] * 255, color.v[2] * 255, color.v[3] * 255)
	            main_ini.settings.draw_font_color = select_color
	            inicfg.save(main_ini, path_last_stay_helper)
			end

			imgui.Separator()

			if imgui.Button(u8"Сбросить цвет", reset_draw_font_color) then
				color.v[1] = bit.rshift(bit.band(color_number, 0xFF0000), 16) / 255
				color.v[2] = bit.rshift(bit.band(color_number, 0x00FF00), 8) / 255
				color.v[3] = bit.band(color_number, 0x0000FF) / 255
				main_ini.settings.draw_font_color = DEFAULT_FONT_COLOR
				inicfg.save(main_ini, path_last_stay_helper)
			end
		end

	  	imgui.End()
	end
end

function ProcessAllItemsCheckbox(index)
	if imgui.Checkbox(u8"Все", toggle_all_items[index]) then
		for i = 1, #server_items[index] do
			toggle_items_data[index][i].v = toggle_all_items[index].v
			main_ini.items_categories[server_items[index][i][3]] = toggle_items_data[index][i].v
			inicfg.save(main_ini, path_last_stay_helper)
		end

		if toggle_all_items[index].v == true then
			total_enabled_items[index] = #server_items[index]
		else
			total_enabled_items[index] = 0
		end
	end
end

function ProcessItemCheckbox(index)
	for i = 1, #server_items[index] do

		if imgui.Checkbox(u8:encode(server_items[index][i][2]), toggle_items_data[index][i]) then
			if toggle_items_data[index][i].v == true then
				total_enabled_items[index] = total_enabled_items[index] + 1
			else
				total_enabled_items[index] = total_enabled_items[index] - 1
			end

			toggle_all_items[index] = imgui.ImBool(total_enabled_items[index] == #server_items[index])

			main_ini.items_categories[server_items[index][i][3]] = toggle_items_data[index][i].v
			inicfg.save(main_ini, path_last_stay_helper)
		end
	end
end

function join_argb(a, r, g, b)
    local argb = b 
    argb = bit.bor(argb, bit.lshift(g, 8))
    argb = bit.bor(argb, bit.lshift(r, 16))
    argb = bit.bor(argb, bit.lshift(a, 24))
    return argb
end

local item_qualities = {"{00FF00}", "{9ACD32}", "{FFFF00}", "{FF4500}"}

function hook.onShowDialog(dialogid, style, title, button1, button2, text)

	if dialogid == DIALOG_INVENTORY_ID then
		if toggle_auto_crowbar_lambing == true then

			local line_index = 0

			for line in text:gmatch('[^\r\n]+') do

				if line_index ~= 0 then
					for _, quality in pairs(item_qualities) do					
						if line:find(quality.."|{FFFFFF} Лом") then
							sampSendDialogResponse(dialogid, 1, line_index - 1, "")
							sampCloseCurrentDialogWithButton(1)
							finded_crowbar = true
							return
						end
					end
				end

				line_index = line_index + 1
			end

			sampAddChatMessage("[Уведомление] {FFFFFF}У вас нет лома в инвентаре или он сломан!", 0xFFFFAA2A)
			toggle_auto_crowbar_lambing = false

		elseif toggle_auto_fill_fuel_can == true then

			local line_index = 0

			for line in text:gmatch('[^\r\n]+') do

				if line_index ~= 0 then
					for _, quality in pairs(item_qualities) do					
						if line:find(quality.."|{FFFFFF} Пустая канистра") then
							sampSendDialogResponse(dialogid, 1, line_index - 1, "")
							sampCloseCurrentDialogWithButton(1)
							finded_empty_fuel_can = true
							return
						end
					end
				end

				line_index = line_index + 1
			end

			sampAddChatMessage("[Уведомление] {FFFFFF}У вас нет канистры в инвентаре или она сломана!", 0xFFFFAA2A)
			toggle_auto_fill_fuel_can = false
		end
		if use_pain_killer == true then
			local line_index = 0

			for line in text:gmatch('[^\r\n]+') do

				if line_index ~= 0 then
					for _, quality in pairs(item_qualities) do					
						if line:find(quality.."|{FFFFFF} Обезболивающее") then
							sampSendDialogResponse(dialogid, 1, line_index - 1, "")
							sampCloseCurrentDialogWithButton(1)
							return
						end
					end
				end

				line_index = line_index + 1
			end

			sampAddChatMessage("[Уведомление] {FFFFFF}У вас нет обезболивающих в инвентаре или она сломана!", 0xFFFFAA2A)
			use_pain_killer = false
		end

	elseif dialogid == DIALOG_USE_ITEM_ID then
		if finded_crowbar == true then
			sampSendDialogResponse(dialogid, 1, 0, "")
			sampCloseCurrentDialogWithButton(1)
			finded_crowbar = false
		elseif finded_empty_fuel_can == true then
			sampSendDialogResponse(dialogid, 1, 0, "")
			sampCloseCurrentDialogWithButton(1)
			finded_empty_fuel_can = false
		end
		if use_pain_killer == true then
			sampSendDialogResponse(dialogid, 1, 0, "")
			sampCloseCurrentDialogWithButton(1)
			use_pain_killer = false
		end
	else
		if toggle_auto_crowbar_lambing == true then
			toggle_auto_crowbar_lambing = false
		elseif toggle_auto_fill_fuel_can == true then
			finded_empty_fuel_can = false
		end
	end
end

function simulateKeyPress(game_key)

	lua_thread.create(function()
		setVirtualKeyDown(game_key, true)
		wait(550) 
		setVirtualKeyDown(game_key, false)
	end)
end

function hook.onServerMessage(color, text)
	if toggle_auto_crowbar_lambing == true then
		if text:find("{FFFFFF} Перед вами нет ни одного ржавого авто") then
			toggle_auto_crowbar_lambing = false
		end

		if text:find("Вы успешно добыли необработанное железо") or text:find("Вы успешно добыли железную пластину") then
			simulateKeyPress(key.VK_Y)
		end
	end

	if toggle_auto_fill_fuel_can == true then
		if text:find("Вы не на заправке и около вас нет Т/С") or text:find("На этой заправке нет топлива!") then
			toggle_auto_fill_fuel_can = false
		end

		if text:find("Вы наполнили Канистру") then
			simulateKeyPress(key.VK_Y)
		end
	end

	if use_pain_killer == true then
		if text:find("Вы не нуждаетесь в обезобливающем!") then
			use_pain_killer = false
		end
	end
end