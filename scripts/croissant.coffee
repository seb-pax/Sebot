## Description
#   <description of the scripts functionality>
#
# Dependencies:
#   "croissant": "1.0"
#
# Configuration:
#   initdata.json is the data to import in firebase
#
# Commands:
#   hubot combien croissant nantes -> affiche le nombre personne
#   qui croissant nantes    -> propose 4 personnes pour la prochaine fois
#   choose croissant nantes -> définit celui qui apporte les croissants la prochaine fois
#
# Notes:
#   use a firebase to save and retrieve data
#
# Author:
#   sopracreau

zero_pad = (x) ->
  if x < 10 then '0'+x else ''+x

date_fr_format = (fulldate) ->
  fulldate.split("\/").reverse().join("\/")

module.exports = (robot) ->
    robot.respond /combien(.*)croissant(.*)nantes/i, (msg) ->
      msg.http("https://croissant-ea614.firebaseio.com/users.json")
      .get() (err, res, body) ->
        try
          json = JSON.parse(body)
          msg.send " #{json.length} personnes participent à la feature team Croissant"
        catch error
          msg.send "KO il faut appeler la maintenance"

    robot.respond /qui(.*)croissant(.*)nantes/i, (msg) ->
      msg.http("https://croissant-ea614.firebaseio.com/users.json?orderBy=\"last\"&limitToFirst=4")
      .get() (err, res, body) ->
        try
          json = JSON.parse(body)
          #msg.send  " body #{body}"
          selected = obj for obj in Object.values(json) when obj.last is "2016/01/01"

          if selected
          then msg.send " @#{selected.login} (#{selected.full_name}) s'est proposé parmi ses pairs."
          else
            msg.send " A qui le tour pour apporter les croissants ?"
            msg.send " Les 4 nominés sont : @#{obj.login} (#{obj.full_name})" for obj in Object.values(json)

          #msg.send "The winner is #{json[msg.random Object.keys(json)].full_name}"

        catch error
          msg.send "KO il faut appeler la maintenance"

    robot.respond /choose croissant nantes (.*)/i, (res) ->
       person = res.match[1]
       today = new Date()
       y = today.getFullYear()
       m = today.getMonth()
       d = today.getDate()
       fulldate = today.getFullYear() + "/" + zero_pad(m) + "/" + zero_pad(d)
       #res.send "person" + person + "date" + fulldate

       res.http("https://croissant-ea614.firebaseio.com/users.json?orderBy=\"login\"&equalTo=\""+person+"\"")
       .get() (err, res2, body) ->
        try
           json = JSON.parse(body)
           key = Object.keys(json)[0]

           #res.send "https://croissant-ea614.firebaseio.com/users/"+key+"/.json" + "{\"last\":\""+fulldate+"\"}"
           res.http("https://croissant-ea614.firebaseio.com/users/"+key+"/.json")
           .patch("{\"last\":\""+fulldate+"\"}") (err, body) ->
             res.send "KO" if err
             res.send "OK mise à jour de " + person + " au " + date_fr_format(fulldate) unless err
        catch error
           res.send "get KO il faut appeler la maintenance" +error

    robot.respond /quand croissant nantes (.*)/i, (res) ->
       person = res.match[1]
       res.http("https://croissant-ea614.firebaseio.com/users.json?orderBy=\"login\"&equalTo=\""+person+"\"")
       .get() (err, res2, body) ->
        try
           json = JSON.parse(body)
           key = Object.keys(json)[0]
           res.send person + " a apporté les croissants le " + date_fr_format(json[key].last)
        catch error
           res.send "get KO il faut appeler la maintenance" + error

  # robot.hear /badger/i, (res) ->
  #   res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
