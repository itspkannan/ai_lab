local redis = require "resty.redis"
local utils = require "utils"

local _M = {}

function _M.check_rate_limit(ip, limit, window)
    local red = redis:new()
    red:set_timeout(1000)

    local ok, err = red:connect("caching_service", 6379)
    if not ok then
        ngx.log(ngx.ERR, "[RateLimit] Redis connect error: ", err)
        return utils.respond_with_error(500, "Internal rate limiting error")
    end

    local key = "ratelimit:" .. ip
    local count, err = red:incr(key)
    if not count then
        ngx.log(ngx.ERR, "[RateLimit] Redis INCR error: ", err)
        return utils.respond_with_error(500, "Rate limiting error")
    end

    if count == 1 then
        red:expire(key, window)
    end

    if count > limit then
        ngx.log(ngx.WARN, "[RateLimit] Limit exceeded for: ", ip)
        return utils.respond_with_error(429, "Rate limit exceeded. Try again later.")
    end
end

return _M
