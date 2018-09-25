# Digilines: Simple Beha Protocol

## Memory
Memory chips store data in a portable format, up to 64 KiB of serialized data for the largest.
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

## Fingerprint Scanner
Very simple, will broadcast a string with the player's name upon punch or rightclick.
