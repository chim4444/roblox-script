local url = "https://raw.githubusercontent.com/chim4444/roblox-script/refs/heads/main/basketball.lua"

local function getHttp()
    return (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
        or (http and http.HttpGet)
end

local function fetch(link)
    local req = getHttp()
    if req then
        local ok, res = pcall(function()
            return req({Url = link, Method = "GET"})
        end)
        if ok and res then
            if type(res) == "table" and res.Body then
                return res.Body
            elseif type(res) == "string" then
                return res
            end
        end
    end
    -- fallback for basic executors
    local ok2, body = pcall(function()
        return game:HttpGet(link)
    end)
    if ok2 then return body end
    return nil
end

local source = fetch(url)
if not source or source == "" then
    warn("[Loader] Failed to fetch script. Check internet / executor.")
    return
end

local fn, err = loadstring(source)
if not fn then
    warn("[Loader] loadstring error:", err)
    return
end

local ok, runErr = pcall(fn)
if not ok then
    warn("[Loader] Script error:", runErr)
end
