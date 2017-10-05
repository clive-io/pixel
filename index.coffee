app = require('express')()
request = require 'request'

app.set 'trust proxy', 'loopback'
app.use require('cloudflare-middleware')()
app.use require('helmet')()

app.all '/', (req, res) ->
  res.sendStatus(200)
app.all '/favicon.ico', (req, res) ->
  res.sendStatus(404)

apicache = {}
ipreport = (ip) ->
  return new Promise (res, rej) ->
    if not apicache[ip]?
      # If not cached, we have to fetch the text for the thing to display, using our API
      request.get 'http://ip-api.com/json/' + ip, (api_err, api_res, api_data) ->
        try
          api_data = JSON.parse api_data
        catch json_err
          api_err = "JSON failed to parse: " + json_err
        if api_err or api_res.statusCode != 200 then apicache[ip] = ip + ', api error (status code ' + api_res.statusCode + '): ' + api_err
        else if api_data?.status != 'success' then apicache[ip] = ip + ', lookup error: ' + api_data?.message + '.'
        else apicache[ip] = ip + ',' +
          ' ISP ' + api_data?.isp +
          (if api_data?.org != api_data?.isp then ' ORG ' + api_data?.org else '') +
          ' FROM ' + api_data?.city + ', ' + api_data?.regionName + ', ' + api_data?.countryCode + '.'
        res(apicache[ip])
    else
      res(apicache[ip])

outbuf = {}
app.all '/:id', (req, res) ->
  # From https://github.com/tblobaum/pixel-tracker
  # Cross-confirmed with http://proger.i-forge.net/%D0%9A%D0%BE%D0%BC%D0%BF%D1%8C%D1%8E%D1%82%D0%B5%D1%80/[20121112]%20The%20smallest%20transparent%20pixel.html
  res.sendFile "pixel.gif", {root: __dirname}
  
  # Display it after a delay of 10 seconds to wait for any multi requests
  key = req.ip + '/' + req.params.id
  if not outbuf[key]?
    outbuf[key] = {n: 0, timeout: null}
  if outbuf[key].timeout?
    clearTimeout outbuf[key].timeout
  outbuf[key].n++
  outbuf[key].timeout = setTimeout () ->
    n = outbuf[key].n
    delete outbuf[key]
    ipreport(req.ip).then (text) ->
      console.log req.params.id + "*" + n + " from " + text
  , 10000

app.all '*', (req, res) ->
  res.sendStatus(404)

app.listen(process.env.PORT || 3040)

console.log("Now serving pixels.")
