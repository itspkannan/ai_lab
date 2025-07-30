local cjson = require "cjson.safe"

local _M = {}

function _M.respond_with_error(status, message)
    ngx.status = status
    ngx.header.content_type = "application/json"
    ngx.say(cjson.encode({ error = message }))
    return ngx.exit(status)
end

return _M
