const app = require('express')()


request = require 'request'

cache = {}
app.all '/:id', (req, res) ->
  console.log req.params.id
  res.sendFile "pixel.gif", {root: __dirname}
  if not cache[req.ip]
    # If not cached, we have to fetch the text for the thing to display, using our API
    cache[req.ip] = {n: 0, text: "", timeout: -1}
    request.get 'http://ip-api.com/json/' + req.ip, (api_err, api_res, api_data) ->
      try
        api_data = JSON.parse api_data
      catch json_err
        return console.error json_err
      if api_err or api_res.statusCode != 200 then cache[req.ip].text = req.ip + ', lookup error.'
      else if api_data?.status != 'success' then cache[req.ip].text = req.ip + ', lookup error: ' + api_data?.message + '.'
      else cache[req.ip].text = req.ip + ',' +
        ' ISP ' + api_data?.isp +
        (if api_data?.org != api_data?.isp then ' ORG ' + api_data?.org else '') +
        ' FROM ' + api_data?.city + ', ' + api_data?.regionName + ', ' + api_data?.countryCode + '.'
  
  # We already have it, just display it after a delay of 10 seconds to wait for any multi requests
  cache[req.ip].n++
  clearTimeout cache[req.ip].timeout
  cache[req.ip].timeout = setTimeout () ->
    console.log "R*" + cache[req.ip].n + " " + cache[req.ip].text
    cache[req.ip].n = 0
  , 10000

app.all '*', (req, res) ->
  console.error("Accessed main page")
  res.sendStatus(200)

app.listen(process.env.PORT)

console.log("Now serving pixels.")
