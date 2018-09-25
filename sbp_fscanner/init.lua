local formspecs = {}

-- Delay handling.
local delayed = {}
local function setdelayed(pos, val)
    delayed[minetest.pos_to_string(pos)] = val
end

local function doscanner(pos, player)
    local meta = minetest.get_meta(pos)
    local channel = meta:get_string("channel")

    -- Rate limit.
    if delayed[minetest.pos_to_string(pos)] then
        minetest.chat_send_player(player:get_player_name(), "The scanner is being used too quickly.")
        return
    end

    -- Send user.
    digiline:receptor_send(pos, digiline.rules.default, channel, player:get_player_name())

    -- Set delay again.
    setdelayed(pos, true)
    minetest.after(meta:get_float("mindelay") or 1.0, setdelayed, pos, nil)
end

minetest.register_node('sbp_fscanner:fscanner', {
	description = 'Digiline Fingerprint Scanner',
	tiles = {'fscanner_side.png', 'fscanner_side.png', 'fscanner_side.png', 'fscanner_side.png', 'fscanner_side.png', 'fscanner_front.png'},
	paramtype2 = 'facedir',
	groups = {cracky = 2},
	sounds = default.node_sound_stone_defaults(),
        digiline =  {
            receptor = {},
            effector = {
                action = function() return end,
            },
	},
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            meta:set_string('channel', '');
            meta:set_float('mindelay', 1);
        end,
        on_destruct = function(pos)
            setdelayed(pos, nil)
        end,
        on_punch = function(pos, node, player)
            local meta = minetest.get_meta(pos)
            local channel = meta:get_string("channel")
            if channel and channel:len() > 0 then
                doscanner(pos, player)
            end
        end,
        on_rightclick = function(pos, node, player)
            local meta = minetest.get_meta(pos)
            local channel = meta:get_string("channel")

            -- If channel set, then fire normally, otherwise show formspec.
            if channel and channel:len() > 0 then
                doscanner(pos, player)
            else
                if minetest.is_protected(pos, player:get_player_name()) then
                    return
                end
                formspecs[player:get_player_name()] = {pos = pos}
                minetest.show_formspec(player:get_player_name(), "sbp_fscanner:fscanner", "field[channel;Channel;"..minetest.formspec_escape(channel).."] field[mindelay;minimum delay;"..minetest.formspec_escape(tostring(meta:get_float('mindelay'))).."]")
            end
        end,
});

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "sbp_fscanner:fscanner" then
        return false
    end

    -- Load information
    local context = formspecs[player:get_player_name()]
    if context then
        local pos = context.pos
        if minetest.is_protected(pos, player:get_player_name()) then
            return
        end
        local meta = minetest.get_meta(pos)
        if fields.channel and fields.mindelay then
            local mindelay = tonumber(fields.mindelay)
            -- Don't want huge delays breaking a scanner.
            if not mindelay or mindelay < 0 or mindelay > 10 then
                minetest.chat_send_player(player:get_player_name(), "The delay must be a number from 0 to 10 seconds.")
                return
            end
            meta:set_string("channel", fields.channel)
            meta:set_float("mindelay", tonumber(fields.mindelay))
        end
    end
end)

minetest.register_craft({
	output = 'sbp_fscanner:fscanner',
	recipe = {
		{'default:steel_ingot', 'default:glass', 'default:steel_ingot'},
		{'default:steel_ingot', 'mesecons_button:button_off', 'default:steel_ingot'},
		{'default:steel_ingot', 'digilines:wire_std_00000000', 'default:steel_ingot'},
	},
});
