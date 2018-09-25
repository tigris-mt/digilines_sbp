# Digilines: Simple Beha Protocol
## Memory
* Storage rating limit is for serialized data.
### Actions
* Note that you can set an optional `id = x` in the action and the response/error will also have this id.
* `{type = "set", data = <any serializable lua data>}`
* `{type = "label", text = "some infotext"}`
* `{type = "get"}`
### Responses
* `{type = "setok", id = 1}`
* `{type = "data", id = 1, data = <data in chip>}`
### Errors
* `{type = "error", error = "serialize", id = 1}`
* `{type = "error", error = "limit", id = 1}`
