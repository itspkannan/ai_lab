local http = require "resty.http"
local cjson = require "cjson.safe"
local utils = require "utils"
local ratelimiter = require "redis_ratelimit"

local client_ip = ngx.var.remote_addr
ratelimiter.check_rate_limit(client_ip, 10, 120)

ngx.req.read_body()
local body_data = ngx.req.get_body_data()
if not body_data then
    return utils.respond_with_error(400, "Missing request body")
end

local decoded = cjson.decode(body_data)
if not decoded or not decoded.prompt then
    return utils.respond_with_error(400, "Missing or invalid prompt")
end

local httpc = http.new()
local res, err = httpc:request_uri("http://security_service:8181/v1/data/itspkannan/security/allow", {
    method = "POST",
    body = cjson.encode({ input = { prompt = decoded.prompt } }),
    headers = { ["Content-Type"] = "application/json" }
})

if not res then
    ngx.log(ngx.ERR, "[OPA] call failed: ", err)
    return utils.respond_with_error(500, "OPA validation failed")
end

local result = cjson.decode(res.body)
if not result or not result.result then
    return utils.respond_with_error(403, "Prompt rejected by policy")
end

ngx.log(ngx.INFO, "[OPA] Prompt approved, forwarding")
