proxy = require 'proxy-agent'
module.exports = (robot) ->
  robot.globalHttpOptions.httpAgent  = proxy('http://marc.proxy.corp.sopra:8080', false)
  robot.globalHttpOptions.httpsAgent = proxy('http://marc.proxy.corp.sopra:8080', true)

