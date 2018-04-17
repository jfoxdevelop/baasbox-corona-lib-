# baasbox-corona-lib-
This library provides wrapper functions for Corona SDK that provide access to the BaasBox REST API.

## Samples
```
local baas = require( "BaasBox" )
-- ServerURL:PORT, ApplicationCode
baas.init("http://serverURL:9001", "1111111")
```
<hr>

```
local callbackFunc = function(event)
-- TODO
end

baas.signUp("userName", "Pass", callbackFunc)
baas.logout(callbackFunc)<
```
<hr>
```
local json = require ("json")
local data = {b=1}

baas.createDocument("CollectionName", data,
  function(event)
    baas.addRoleDocumentPermission("level", json.decode(event.response).data.id, "read", "registered",
       function(e)
          print("Permission done...")
       end)
  end)
```
<hr>
```
local json = require ("json")
baas.getDocument("level", "625ff1cf-a0c0-414a-908e-280c79854d19",
  function(event)
    print(json.decode(event.response).result)
    print(json.decode(event.response).data.levelData.data)
  end)
```
