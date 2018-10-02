local m = {
    sizes = {1, 2, 4, 8, 16, 32, 64},
}
sbp_memory = m

function m.nn(x)
    return "sbp_memory:" .. x
end

-- Boxes from Digiline RTC.
local chip_nodebox = {
    type = "fixed",
    fixed = {
        {-8/16, -8/16, -8/16, 8/16, -7/16, 8/16},
        {-7/16, -7/16, -7/16, 7/16, -5/16,  7/16},
    }
}

local chip_selbox = {
    type = "fixed",
    fixed = {{-8/16, -8/16, -8/16, 8/16, -3/16, 8/16}}
}

local function reply(pos, msg)
    digiline:receptor_send(pos, digiline.rules.default, minetest.get_meta(pos):get_string("channel"), msg)
end

for i,size in ipairs(m.sizes) do
    local function label(text)
        local b = "Digiline Memory Chip (" .. size .. " KiB)"
        if text then
            return b .. " (" .. text .. ")"
        else
            return b
        end
    end

    local function init(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", "field[label;Label;${label}] field[channel;Channel;${channel}]")
        if not meta:get_string("channel") then
            meta:set_string("channel", "")
        end
        if not meta:get_string("label") then
            meta:set_string("label", "")
        end
        if not meta:get_string("data") or meta:get_string("data") == "" then
            meta:set_string("data", "return {}")
        end
        meta:set_string("infotext", label(meta:get_string("label")))
    end

    minetest.register_node(m.nn(size), {
        description = label(),
        drawtype = "nodebox",
        -- Thanks for the texture, jogag!
        tiles = {"sbp_memory.png"},
        stack_max = 1,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = {dig_immediate = 2, sbp_memory = 1},
        selection_box = chip_selbox,
        node_box = chip_nodebox,
        sbp_set = function(meta, data)
            local ok, serialized = pcall(minetest.serialize, data)
            if ok then
                if #serialized > size * 1024 then
                    return false, "limit"
                end
                meta:set_string("data", serialized)
                return true
            else
                return false, "serialize"
            end
        end,
        digiline = {
            receptor = {},
            effector = {
                action = function(pos, node, channel, msg)
                    local meta = minetest.get_meta(pos)
                    if channel ~= meta:get_string("channel") then
                        return
                    end
                    if type(msg) ~= "table" then
                        return
                    end
                    local data = minetest.deserialize(meta:get_string("data")) or {}
                    if msg.type == "label" then
                        meta:set_string("label", tostring(msg.text))
                        meta:set_string("infotext", label(tostring(msg.text)))
                    elseif msg.type == "get" then
                        reply(pos, {
                            type = "data",
                            id = msg.id,
                            data = data,
                        })
                    elseif msg.type == "set" then
                        local ok, err = minetest.registered_items[m.nn(size)].sbp_set(meta, msg.data)
                        if ok then
                            reply(pos, {type = "setok", id = msg.id})
                        else
                            reply(pos, {type = "error", error = err, id = msg.id})
                        end
                    end
                end,
            },
        },

        on_construct = init,

        on_receive_fields = function(pos, _, fields, sender)
            local meta = minetest.get_meta(pos)
            if minetest.is_protected(pos, sender:get_player_name()) then
                minetest.record_protection_violation(pos, sender:get_player_name())
                return
            end
            if fields.channel then meta:set_string("channel", fields.channel) end
            if fields.label then meta:set_string("label", fields.label) end
            meta:set_string("infotext", label(meta:get_string("label")))
        end,

        on_dig = function (pos, node, digger)
            if minetest.is_protected(pos, digger:get_player_name()) then
                minetest.record_protection_violation(pos, digger:get_player_name())
                return
            end
            local meta = minetest.get_meta(pos)
            local stack = ItemStack({
                    name = m.nn(size),
            })

            -- Set itemstack data.
            local data = {
                data = meta:get_string("data") or "",
                channel = meta:get_string("channel") or "",
                label = meta:get_string("label") or "",
            }
            data.description = label(data.label)
            stack:get_meta():from_table({fields = data})

            -- Standard logic.
            stack = digger:get_inventory():add_item("main", stack)
            if not stack:is_empty() then
                    minetest.item_drop(stack, digger, pos)
            end
            minetest.remove_node(pos)
            digiline:update_autoconnect(pos)
        end,

        on_place = function(itemstack, placer, pointed_thing)
            -- Standard logic.
            local plname = placer:get_player_name()
            local pos = pointed_thing.under
            local node = minetest.get_node_or_nil(pos)
            local def = node and minetest.registered_nodes[node.name]
            if not def or not def.buildable_to then
                    pos = pointed_thing.above
                    node = minetest.get_node_or_nil(pos)
                    def = node and minetest.registered_nodes[node.name]
                    if not def or not def.buildable_to then return itemstack end
            end
            if minetest.is_protected(pos, placer:get_player_name()) then
                minetest.record_protection_violation(pos, placer:get_player_name())
                return itemstack
            end
            local fdir = minetest.dir_to_facedir(placer:get_look_dir())
            minetest.set_node(pos, {
                    name = m.nn(size),
                    param2 = fdir,
            })

            -- Set meta from item.
            local meta = minetest.get_meta(pos)
            local data = itemstack:get_meta():to_table().fields
            meta:set_string("data", data.data or "")
            meta:mark_as_private("data")
            meta:set_string("label", data.label or "")
            meta:set_string("channel", data.channel or "")
            meta:set_string("infotext", label(meta:get_string("label")))

            digiline:update_autoconnect(pos)

            if not minetest.setting_getbool("creative_mode") then
                itemstack:take_item()
            end
            return itemstack
        end,
    })
    if i ~= 1 then
        minetest.register_craft{
            output = m.nn(size),
            type = "shapeless",
            recipe = {
                m.nn(m.sizes[i - 1]),
                m.nn(m.sizes[i - 1]),
            },
        }
    end
end

minetest.register_craft({
	output = m.nn(1),
	recipe = {
                {"", "mesecons_materials:silicon", ""},
                {"mesecons_materials:silicon", "mesecons_luacontroller:luacontroller0000", "mesecons_materials:silicon"},
                {"mesecons_materials:fiber", "digilines:wire_std_00000000", "mesecons_materials:fiber"},
        },
})
