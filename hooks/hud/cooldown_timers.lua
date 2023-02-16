local _sdk = rawget(_G, "_sdk") --* requires version 1.2 or above
local _updator = rawget(_G, "_updator")

if not rawget(_G, "CustomTimerPanel") then
	rawset(_G, "CustomTimerPanel", {})
	function CustomTimerPanel:init()
		self._initialized = true

		self._ws = managers.gui_data:create_fullscreen_workspace()
		self._panel = self._ws:panel():panel({
			visible = false,
			alpha = 1,
			layer = 150,
		})

		self:setup_panels()
	end

	function CustomTimerPanel:setup_panels()
		if not self._initialized then
			self:init()
			return
		end

		self._panel:clear()

		self._timer_panel = self._panel:panel({
			w = self._panel:w() / 4,
			h = 12,
		})
		self._timer_panel:rect({
			name = "background",
			color = Color.black,
			alpha = 0.4,
			layer = -1,
		})
		self._timer_panel:rect({
			name = "progress_bar",
			color = Color.white,
			alpha = 0.4,
			layer = -1,
			x = 2,
			y = 2,
			w = self._timer_panel:w() - 4,
			h = self._timer_panel:h() - 4,
		})

		self._timer_panel:set_world_center_x(self._panel:center_x())
		self._timer_panel:set_world_center_y(self._panel:h() * 0.75)

		self._timer_text = self._panel:text({
			text = "0.00s",
			font = "fonts/font_univers_530_bold",
			font_size = 22,
			x = 4,
			y = 4,
		})
		_sdk:update_text_rect(self._timer_text)

		self._timer_text:set_leftbottom(self._timer_panel:lefttop())
	end

	function CustomTimerPanel:update_gui(show)
		local ct = self._current_timer and self._current_timer >= -0.5
		if ct and self._max_t and show then
			self._panel:show()

			self._timer_text:set_text(string.format("%.2fs", self._current_timer))
			_sdk:update_text_rect(self._timer_text)

			local fill_precentage = math.clamp(self._current_timer / self._max_t, 0, 1)
			local bg = self._timer_panel:child("background")
			local bar = self._timer_panel:child("progress_bar")
			bar:set_w((bg:w() - 4) * fill_precentage)
			return
		end

		self._panel:hide()
		self._max_t = nil
	end

	function CustomTimerPanel:update_fire_timer()
		if not D:conf("_hud_shotgun_fire_timer") then
			return false
		end

		local state = _sdk:player_movement_state()
		local weapon_base = state and alive(state._equipped_unit) and state._equipped_unit:base()
		if weapon_base and not weapon_base:start_shooting_allowed() then
			local name_id = weapon_base._name_id
			if name_id ~= "r870_shotgun" and name_id ~= "mossberg" then
				return false
			end

			self._current_timer = tonumber(weapon_base._next_fire_allowed - _sdk:current_game_time()) or 0
			if not self._max_t then
				self._max_t = self._current_timer
			end

			return true
		end

		return false
	end

	function CustomTimerPanel:update_reload_timer()
		if not D:conf("_hud_reload_timer") then
			return false
		end

		local state = _sdk:player_movement_state()
		if state and state._is_reloading and state:_is_reloading() then
			self._current_timer = tonumber(state:_is_reloading() - _sdk:current_game_time()) or 0
			-- todo: find a proper way to reset self._max_t when entering state._reload_exit_expire_t
			if not self._max_t or (self._max_t and (self._current_timer > self._max_t)) then
				self._max_t = self._current_timer
			end

			return true
		end

		return false
	end

	function CustomTimerPanel:update()
		if not self._initialized then
			self:init()
		end

		local result
		result = result or self:update_fire_timer()
		result = result or self:update_reload_timer()
		self:update_gui(result)
	end

	_updator:add(function()
		CustomTimerPanel:update()
	end, "_hud_reload_timer_update")
end
