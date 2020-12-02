local BasePlugin = require "kong.plugins.base_plugin"
local constants = require "kong.constants"

local kong = kong
local type = type
local error = error


local MockHandler = {
  PRIORITY = 1003,
  VERSION = "1.0.0",
}

function MockHandler:new()
    MockHandler.super.new(self, "mock")
end

function MockHandler:init_worker()
    MockHandler.super.init_worker(self)
    -- Custome Logic Implementation  here--
end

function MockHandler:access(config)
  -- check if preflight request and whether it should be authenticated
  if not conf.run_on_preflight and kong.request.get_method() == "OPTIONS" then
    return
  end

  if conf.anonymous and kong.client.get_credential() then
    -- we're already authenticated, and we're configured for using anonymous,
    -- hence we're in a logical OR between auth methods and we're already done.
    return
  end

  local ok, err = do_authentication(conf)
  if not ok then
    if conf.anonymous then
      -- get anonymous user
      local consumer_cache_key = kong.db.consumers:cache_key(conf.anonymous)
      local consumer, err = kong.cache:get(consumer_cache_key, nil,
                                           kong.client.load_consumer,
                                           conf.anonymous, true)
      if err then
        return error(err)
      end

      set_consumer(consumer)

    else
      return kong.response.error(err.status, err.message, err.headers)
    end
  end
end

return MockHandler
