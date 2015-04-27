--Minetest
--Copyright (C) 2014 sapier
--
--This program is free software; you can redistribute it and/or modify
--it under the terms of the GNU Lesser General Public License as published by
--the Free Software Foundation; either version 2.1 of the License, or
--(at your option) any later version.
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Lesser General Public License for more details.
--
--You should have received a copy of the GNU Lesser General Public License along
--with this program; if not, write to the Free Software Foundation, Inc.,
--51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

--------------------------------------------------------------------------------
local function get_formspec(tabview, name, tabdata)

	local index = menudata.worldlist:get_current_index(
				tonumber(core.setting_get("mainmenu_last_selected_world"))
				)

	local retval =
		"image_button[4,4.15;2.6,0.8;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_button.png;world_delete;" .. fgettext("Delete") .. "]" ..
		"image_button[6.5,4.15;2.8,0.8;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_button.png;world_create;" .. fgettext("New") .. "]" ..
		"image_button[9.2,4.15;2.55,0.8;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_button.png;world_configure;" .. fgettext("Configure") .. "]" ..
		"image_button[8.5,4.95;3.25,0.8;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_button.png;start_server;" .. fgettext("Start Game") .. "]" ..
		"label[4,-0.25;" .. fgettext("Select World:") .. "]" ..
		"checkbox[0.25,0.15;cb_creative_mode;" .. fgettext("Creative Mode") .. ";" ..
		dump(core.setting_getbool("creative_mode")) .. "]" ..
		"checkbox[0.25,0.6;cb_enable_damage;" .. fgettext("Enable Damage") .. ";" ..
		dump(core.setting_getbool("enable_damage")) .. "]" ..
		"image[0.25,1.3;0.58,0.55;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_checkf.png]"..
		"image[0.25,1.3;0.58,0.55;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_check.png]"..
		"image_button[0.8,1.3;3,0.8;"..minetest.formspec_escape(mm_texture.basetexturedir).."menu_trans.png;btn_single;Local Server;false;false]"..
		"checkbox[0.25,1.6;cb_server_announce;" .. fgettext("Public") .. ";" ..
		dump(core.setting_getbool("server_announce")) .. "]" ..
		"label[0.25,2.2;" .. fgettext("Name/Password") .. "]" ..
		"field[0.55,3.2;3.5,0.5;te_playername;;" ..
		core.formspec_escape(core.setting_get("name")) .. "]" ..
		"pwdfield[0.55,4;3.5,0.5;te_passwd;]"

	local bind_addr = core.setting_get("bind_address")
	if bind_addr ~= nil and bind_addr ~= "" then
		retval = retval ..
			"field[0.55,5.2;2.25,0.5;te_serveraddr;" .. fgettext("Bind Address") .. ";" ..
			core.formspec_escape(core.setting_get("bind_address")) .. "]" ..
			"field[2.8,5.2;1.25,0.5;te_serverport;" .. fgettext("Port") .. ";" ..
			core.formspec_escape(core.setting_get("port")) .. "]"
	else
		retval = retval ..
			"field[0.55,5.2;3.5,0.5;te_serverport;" .. fgettext("Server Port") .. ";" ..
			core.formspec_escape(core.setting_get("port")) .. "]"
	end

	retval = retval ..
		"textlist[4,0.25;7.5,3.7;srv_worlds;" ..
		menu_render_worldlist() ..
		";" .. index .. "]"

	return 'size[12,5.4;false]'..retval
end

--------------------------------------------------------------------------------
local function main_button_handler(this, fields, name, tabdata)

	local world_doubleclick = false

	if fields["btn_single"]~=nil then
		local single = create_tab_single(true)
		single:set_parent(this.parent)
		single:show()
		this:hide()
		return true
	end

	if fields["srv_worlds"] ~= nil then
		local event = core.explode_textlist_event(fields["srv_worlds"])

		local selected = core.get_textlist_index("srv_worlds")
		if selected ~= nil then
			local filename = menudata.worldlist:get_list()[selected].path
			local worldconfig = modmgr.get_worldconfig(filename)
			filename = filename .. DIR_DELIM .. "world.mt"

			if worldconfig.creative_mode ~= nil then
				core.setting_set("creative_mode", worldconfig.creative_mode)
			else
				local worldfile = Settings(filename)
				worldfile:set("creative_mode", core.setting_get("creative_mode"))
				if not worldfile:write() then
					core.log("error", "Failed to write world config file")
				end
			end
			if worldconfig.enable_damage ~= nil then
				core.setting_set("enable_damage", worldconfig.enable_damage)
			else
				local worldfile = Settings(filename)
				worldfile:set("enable_damage", core.setting_get("enable_damage"))
				if not worldfile:write() then
					core.log("error", "Failed to write world config file")
				end
			end
		end

		if event.type == "DCL" then
			world_doubleclick = true
		end
		if event.type == "CHG" then
			core.setting_set("mainmenu_last_selected_world",
				menudata.worldlist:get_raw_index(core.get_textlist_index("srv_worlds")))
			return true
		end
	end

	if menu_handle_key_up_down(fields,"srv_worlds","mainmenu_last_selected_world") then
		return true
	end

	if fields["cb_creative_mode"] then
		core.setting_set("creative_mode", fields["cb_creative_mode"])
		local selected = core.get_textlist_index("srv_worlds")
		local filename = menudata.worldlist:get_list()[selected].path ..
				DIR_DELIM .. "world.mt"

		local worldfile = Settings(filename)
		worldfile:set("creative_mode", fields["cb_creative_mode"])
		if not worldfile:write() then
			core.log("error", "Failed to write world config file")
		end
		return true
	end

	if fields["cb_enable_damage"] then
		core.setting_set("enable_damage", fields["cb_enable_damage"])
		local selected = core.get_textlist_index("srv_worlds")
		local filename = menudata.worldlist:get_list()[selected].path ..
				DIR_DELIM .. "world.mt"

		local worldfile = Settings(filename)
		worldfile:set("enable_damage", fields["cb_enable_damage"])
		if not worldfile:write() then
			core.log("error", "Failed to write world config file")
		end
		return true
	end

	if fields["cb_server_announce"] then
		core.setting_set("server_announce", fields["cb_server_announce"])
		return true
	end

	if fields["start_server"] ~= nil or
		world_doubleclick or
		fields["key_enter"] then
		local selected = core.get_textlist_index("srv_worlds")
		if selected ~= nil then
			gamedata.playername     = fields["te_playername"]
			gamedata.password       = fields["te_passwd"]
			gamedata.port           = fields["te_serverport"]
			gamedata.address        = ""
			gamedata.selected_world = menudata.worldlist:get_raw_index(selected)

			core.setting_set("port",gamedata.port)
			if fields["te_serveraddr"] ~= nil then
				core.setting_set("bind_address",fields["te_serveraddr"])
			end

			--update last game
			local world = menudata.worldlist:get_raw_element(gamedata.selected_world)

			local game,index = gamemgr.find_by_gameid(world.gameid)
			core.setting_set("menu_last_game",game.id)
			core.start()
			return true
		end
	end

	if fields["world_create"] ~= nil then
		local create_world_dlg = create_create_world_dlg(true)
		create_world_dlg:set_parent(this)
		create_world_dlg:show()
		this:hide()
		return true
	end

	if fields["world_delete"] ~= nil then
		local selected = core.get_textlist_index("srv_worlds")
		if selected ~= nil and
			selected <= menudata.worldlist:size() then
			local world = menudata.worldlist:get_list()[selected]
			if world ~= nil and
				world.name ~= nil and
				world.name ~= "" then
				local index = menudata.worldlist:get_raw_index(selected)
				local delete_world_dlg = create_delete_world_dlg(world.name,index)
				delete_world_dlg:set_parent(this)
				delete_world_dlg:show()
				this:hide()
			end
		end

		return true
	end

	if fields["world_configure"] ~= nil then
		local selected = core.get_textlist_index("srv_worlds")
		if selected ~= nil then
			local configdialog =
				create_configure_world_dlg(
						menudata.worldlist:get_raw_index(selected))

			if (configdialog ~= nil) then
				configdialog:set_parent(this)
				configdialog:show()
				this:hide()
			end
		end
		return true
	end
	return false
end

--------------------------------------------------------------------------------
tab_server = {
	name = "server",
	caption = fgettext("Server"),
	cbf_formspec = get_formspec,
	cbf_button_handler = main_button_handler,
	on_change = nil
	}

function create_tab_server()
		local retval = dialog_create("server",
										get_formspec,
										main_button_handler,
										nil)
	return retval
end