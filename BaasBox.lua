---------------------------------------------------------------------------------
--
-- BaasBox module for Corona SDK
-- @copyright jfox 2016
-- @author Peter Schleining
-- @version 1.0
-- @see baasbox.com
--
---------------------------------------------------------------------------------

local json = require("json")
local url = require("socket.url")
local BaasBox = {}

local baas = {
  baseUrl = "",
  subURL = "",
  appcode = "",
  username = "",
  password = "",
  session = ""
}

local timeoutSec = 8

---------------------------------------------------------------------------------

BaasBox.init = function(url, appcode) 
  baas.baseUrl = url
  baas.appcode = appcode
end

BaasBox.setSessionToken = function(session)
  	baas.session = session
end

---------------------------------------------------------------------------------

-- REQUEST
BaasBox.request = function(subURL, requestType, cb, headers, body) 
  local params = {}
  params.headers = headers
  params.body = json.encode(body)
  params.timeout = timeoutSec

  network.request(baas.baseUrl .. "/" .. subURL, requestType, 
    function(event)

      if event.status == -1 then
        network.request(baas.baseUrl .. "/" .. subURL, requestType, cb, params)
      else
        cb(event)
      end  
    end, params)
end

BaasBox.requestFile = function(subURL, cb, headers, filename, directory) 
  local params = {}
  params.headers = headers
  params.response = {
	    filename = filename,
	    baseDirectory = directory
  }
  params.timeout = timeoutSec
  params.body = json.encode(body)

  local function PostPrepair(event)
		local ltn12 = require "ltn12"
		local mime = require "mime"

		local path = system.pathForFile( filename, directory )
		local elFile = io.open( path, "rb" )
		local mystring = elFile:read( "*a" )
		local outpath = system.pathForFile( filename, directory )

		ltn12.pump.all(
		  ltn12.source.string(mystring),
		  ltn12.sink.chain(
		    mime.decode("base64"),
		    ltn12.sink.file(io.open(outpath,"w"))
		  )
		)
		cb(event)
  end	
  network.request(baas.baseUrl .. "/" .. subURL .. "&charset=utf-8;base64", "GET", PostPrepair, params)
end

-- UPLOAD
BaasBox.uploadFile = function(filename, baseDirectory, contentType, CallBack) 
  local params = {}
  params.timeout = timeoutSec
  local MultipartFormData = require ("lib.multipartForm")

  local multipart = MultipartFormData.new()
  multipart:addHeader("X-BB-SESSION", baas.session)

  multipart:addFile("filename", system.pathForFile(filename, baseDirectory ), contentType, filename)

  params.body = multipart:getBody() -- Must call getBody() first!
  params.headers = multipart:getHeaders() -- Headers not valid until getBody() is called.

  network.request( baas.baseUrl .. "/file", "POST", CallBack, params)
end

---------------------------------------------------------------------------------

-- Sign up
BaasBox.signUp = function(username, password, cb) 
  local requestType = "POST"
  local subURL = "user"
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BAASBOX-APPCODE"] = baas.appcode

  local body = {
  		username = username,
  		password = password,
  }

  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Login
BaasBox.login = function(username, password, cb) 
  local requestType = "POST"
  local subURL = "login"
  local headers = {}
  headers["Content-type"] = "application/json"
  local body = {
  		username = username,
  		password = password,
  		appcode = baas.appcode,
  		}
  		--body="&username=".. username .."&password="..password.."&appcode="..baas.appcode
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Logout
BaasBox.logout = function(cb) 
  local requestType = "POST"
  local subURL = "logout"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Logged user profile
BaasBox.getProfile = function(cb) 
  local requestType = "GET"
  local subURL = "me"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Update user profile
BaasBox.updateProfile = function(data, cb) 
  local requestType = "PUT"
  local subURL = "me"
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = data --TODO
  BaasBox.request(subURL, requestType, cb, headers, body)
end

--Fetch a user profile
BaasBox.getUserProfile = function(userName, cb) 
  local requestType = "GET"
  local subURL = "user/" .. userName --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Fetch users
BaasBox.getUsers = function(cb) 
  local requestType = "GET"
  local subURL = "users"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Change password
BaasBox.changePassword = function(old, new, cb) 
  local requestType = "PUT"
  local subURL = "me/password"
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = {
  		old = old,
  		new = new,
  }
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Change username
BaasBox.changeUsername = function(username, cb) 
  local requestType = "PUT"
  local subURL = "me/username"
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = {
  		username = username
  }
  BaasBox.request(subURL, requestType, cb, headers, body)
end

--Password reset
BaasBox.resetPassword = function(username, cb) 
  local requestType = "GET"
  local subURL = "user/"..username.."/password/reset"  --TODO
  local headers = {}
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve all social network connections for a connected user
BaasBox.getSocial = function(cb) 
  local requestType = "GET"
  local subURL = "social"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Login a User with a specified social network
BaasBox.loginSocial = function(socialNetwork, OAUTH_TOKEN, OAUTH_SECRET, cb) 
  local requestType = "POST"
  local subURL = "social/"..socialNetwork --TODO
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {
  		oauth_token = OAUTH_TOKEN,
  		oauth_secret = OAUTH_SECRET
  }
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Link a user to a specified social network
BaasBox.linkToSocial = function(socialNetwork, OAUTH_TOKEN, OAUTH_SECRET, cb) 
  local requestType = "PUT"
  local subURL = "social/"..socialNetwork --TODO
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = {
  		oauth_token = OAUTH_TOKEN,
  		oauth_secret = OAUTH_SECRET
  }
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Unlink a user from a specified social network
BaasBox.unlinkToSocial = function(socialNetwork, cb) 
  local requestType = "DELETE"
  local subURL = "social/"..socialNetwork --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Follow a user
BaasBox.followUser = function(username, cb) 
  local requestType = "POST"
  local subURL = "follow/"..username --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Unfollow a user
BaasBox.unfollowUser = function(username, cb) 
  local requestType = "DELETE"
  local subURL = "follow/"..username --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Fetch following
BaasBox.getFollowing = function(username, cb) 
  local requestType = "GET"
  local subURL = "following/"..username --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Fetch followers
BaasBox.getFollowers = function(username, cb) 
  local requestType = "GET"
  local subURL = "followers/"..username --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Enable push notifications
BaasBox.setNotofications = function(os, pushToken, cb) 
  local requestType = "PUT"
  local subURL = "push/enable/"..os.."/"..pushToken --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Disable push notifications
BaasBox.unsetNotofications = function(os, pushToken, cb) 
  local requestType = "PUT"
  local subURL = "push/disable/"..os.."/"..pushToken --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Send a push notification
BaasBox.sendPush = function(message, user, cb) 
  local requestType = "POST"
  local subURL = "push/message/"
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = {
  		message = message,
  		users = user
  }
  BaasBox.request(subURL, requestType, cb, headers, body)
end


-- Create a new Collection
BaasBox.createCollection = function(collection, cb) 
  local requestType = "POST"
  local subURL = "admin/collection/"..collection
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Delete a Collection
BaasBox.deleteCollection = function(collection, cb) 
  local requestType = "DELETE"
  local subURL = "admin/collection/"..collection
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Create a document
-- "'{"title" : "My new post title", "body" : "Body of my post."}'"
BaasBox.createDocument = function(collection, data, cb) 
  BaasBox.createDocumentId(collection, nil, data, cb)
end

-- Create a document
-- "'{"title" : "My new post title", "body" : "Body of my post."}'"
BaasBox.createDocumentId = function(collection, id, data, cb) 
  local requestType = "POST"
  local subURL = "document/"..collection

  if (id ~= nil) then
    subURL = subURL.. "/" .. id
  end 

  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = data
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve documents
BaasBox.getDocument = function(collection, id, cb) 
  local requestType = "GET"
  local subURL = "document/" .. collection .. "/" .. id
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve documents by a query
BaasBox.getDocuments = function(collection, cb, filter) 
  local requestType = "GET"
  local subURL
  if filter then
  	subURL = "document/" .. collection .. "?" .. filter
  else
  	subURL = "document/" .. collection
  end	

  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Count documents
BaasBox.countDocuments = function(collection, cb) 
  local requestType = "GET"
  local subURL = "document/"..collection.."/count" -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Modify a document
-- '{"title" : "My new post title", "body" : "New body of post.", "tags" : "tag1"}'
BaasBox.editDocument = function(collection, id, data, cb) 
  local requestType = "PUT"
  local subURL = "document/" .. collection .. "/" .. id -- TODO
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = data  --TODO
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Update a Document’s field
-- "'{"data" : "Updated title"}'"
BaasBox.updateDocument = function(collection, id, fieldName, value, cb) 
  local requestType = "PUT"
  local subURL = "document/" .. collection .. "/" .. id .. "/." .. fieldName -- TODO
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local data = {}
  data.data = value
  local body = data --TODO
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Delete a document
BaasBox.deleteDocument = function(collection, id, cb) 
  local requestType = "DELETE"
  local subURL = "document/" .. collection .. "/" .. id -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Grant permissions on a Document
BaasBox.addUserDocumentPermission = function(collection, id, action, username, cb) 
  local requestType = "PUT"
  local subURL = "document/"..collection.."/"..id.."/"..action.."/user/"..username -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Grant permissions on a Document
BaasBox.addRoleDocumentPermission = function(collection, id, action, rolename, cb) 
  local requestType = "PUT"
  local subURL = "document/"..collection.."/"..id.."/"..action.."/role/"..rolename -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Revoke permissions on a Document
BaasBox.removeUserDocumentPermission = function(collection, id, action, username, cb) 
  local requestType = "DELETE"
  local subURL = "document/"..collection.."/"..id.."/"..action.."/user/"..username -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Revoke permissions on a Document
BaasBox.removeRoleDocumentPermission = function(collection, id, action, rolename, cb) 
  local requestType = "DELETE"
  local subURL = "document/"..collection.."/"..id.."/"..action.."/role/"..rolename -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Create a link
BaasBox.createLink = function(sourceId, label, destId, cb) 
  local requestType = "POST"
  local subURL = "link/"..sourceId.."/"..label.."/"..destId -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve links
BaasBox.getLink = function(id, cb) 
  local requestType = "GET"
  local subURL = "link/"..id -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Delete links
BaasBox.deleteLink = function(id, cb) 
  local requestType = "DELETE"
  local subURL = "link/"..id -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Delete a file
BaasBox.deleteFile = function(id, cb) 
  local requestType = "DELETE"
  local subURL = "file/"..id -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve a file
BaasBox.getFile = function(id, filename, directory, cb) 
  local subURL = "file/"..id .. "?download=true"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.requestFile(subURL, cb, headers, filename, directory)
end

-- Retrieve details of a file
BaasBox.getFileDetails = function(id, cb) 
  local requestType = "GET"
  local subURL = "file/details/"..id -- TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve details of files
BaasBox.getFiles = function(cb) 
  local requestType = "GET"
  local subURL = "file/details"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Grant access to a file
BaasBox.setUserFilePermission = function(id, action, username, cb) 
  local requestType = "PUT"
  local subURL = "file/" .. id .. "/" .. action .. "/user/" .. username  --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Grant access to a file
BaasBox.setRoleFilePermission = function(id, action, rolename, cb) 
  local requestType = "PUT"
  local subURL = "file/"..id.."/"..action.."/role/"..rolename  --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Revoke access to a file
BaasBox.removeUserFilePermission = function(id, action, username, cb) 
  local requestType = "DELETE"
  local subURL = "file/"..id.."/"..action.."/user/"..username  --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Revoke access to a file
BaasBox.removeRoleFilePermission = function(id, action, rolename, cb) 
  local requestType = "DELETE"
  local subURL = "file/"..id.."/"..action.."/role/"..rolename  --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Create an asset
--"'name=margherita&meta={"pizzaname": "Margherita", "price": 5}'"
BaasBox.createAsset = function(data, cb) 
  local requestType = "POST"
  local subURL = "admin/asset"
  local headers = {}
  headers["Content-type"] = "application/json"
  headers["X-BB-SESSION"] = baas.session
  local body = data  -- TODO
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Retrieve an Asset
BaasBox.getAsset = function(name, cb) 
  local requestType = "GET"
  local subURL = "asset/" .. name  --TODO
  local headers = {}
  headers["X-BAASBOX-APPCODE"] = baas.appcode
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Delete an asset
BaasBox.deleteAsset = function(name, cb) 
  local requestType = "DELETE"
  local subURL = "admin/asset/"..name  --TODO
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end

-- Fetch assets
BaasBox.getAssets = function(cb)
  local requestType = "GET"
  local subURL = "admin/asset"
  local headers = {}
  headers["X-BB-SESSION"] = baas.session
  local body = {}
  BaasBox.request(subURL, requestType, cb, headers, body)
end


return BaasBox
