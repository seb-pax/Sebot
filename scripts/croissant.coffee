# Description
#   <description of the scripts functionality>
#
# Dependencies:
#   "croissant": "1.0"
#
# Configuration:
#   initdata.json is the initial data to import in firebase
#
# Commands:
#   lopako croissant (nantes|toulouse) combien -> affiche le nombre de personnes dans la feature team Croissant
#   lopako croissant (nantes|toulouse) qui     -> propose 4 personnes pour la prochaine fois
#   lopako croissant (nantes|toulouse) elu     -> définit celui qui apporte les croissants la prochaine fois
#   lopako croissant (nantes|toulouse) update  -> modifie la date de celui qui a apporté les croissants
#   lopako croissant (nantes|toulouse) quand  -> affiche la dernière date où une personne a apporté les croissants
#
# Notes:
#   use a firebase to save and retrieve data
#
# Author:
#   sopracreau
proxy = require 'proxy-agent'

ROOT_FIREBASE_NANTES="https://croissant-ea614.firebaseio.com/"
ROOT_FIREBASE_TOULOUSE="https://croissant-toulouse.firebaseio.com/"
PROXY='http://marc.proxy.corp.sopra:8080'

COUNT_OF_NOMINATED=6
VALUE_OF_ELECTED="2016/01/01"

zero_pad = (x) ->
  if x < 10 then '0'+x else ''+x

date_fr_format = (fulldate) ->
  fulldate.split("\/").reverse().join("\/")

update_date = (firebase, res, person , fulldate) ->
  res.http(firebase + "/users.json?orderBy=\"login\"&equalTo=\""+person+"\"",
      {'agent':proxy(PROXY, false)} )
  .get() (err, res2, body) ->

      json = JSON.parse(body)
      key = Object.keys(json)[0]

      res.http(firebase + "users/"+key+"/.json", {'agent':proxy(PROXY, false)} )
      .patch("{\"last\":\""+fulldate+"\"}") (err, body) ->
          res.send "KO " if err
          if fulldate is VALUE_OF_ELECTED
          then res.send "OK " + person + " est le nouvel élu " unless err
          else res.send "OK mise à jour de " + person + " au " + date_fr_format(fulldate) unless err

#TIMEZONE = "Europe/Paris"
#QUITTING_TIME = '* * 16 * * 2-6' # M-F 5pm
#ROOM = "Croissants"

#cronJob = require('cron').CronJob
combien_croissant = (firebase, msg) ->
  msg.http(firebase + "users.json", {'agent':proxy(PROXY, false)} )
  .get() (err, res, body) ->
    try
      json = JSON.parse(body)
      msg.send "#{json.length} personnes participent à la feature team Croissant"
    catch error
      msg.send "KO il faut appeler la maintenance" + error

qui_croissant = (firebase, msg) ->
  msg.http(firebase + "users.json?orderBy=\"last\"&limitToFirst=" + COUNT_OF_NOMINATED,
      {'agent':proxy(PROXY, false)} )
  .get() (err, res, body) ->
    try
      json = JSON.parse(body)
      values = Object.keys(json).map((key) => return json[key])
      selected =  obj for obj in values when obj and obj.last is VALUE_OF_ELECTED

      if selected
      then msg.send " @#{selected.login} (#{selected.full_name}) s'est proposé et apportera les croissants."
      else
        msg.send "A qui le tour pour apporter les croissants ?"
        msg.send "Les #{COUNT_OF_NOMINATED} nominés sont : "
        msg.send "\t\t @#{obj.login} (#{obj.full_name})" for obj in values
    catch error
      msg.send "KO il faut appeler la maintenance" + error

elu_croissant = (firebase, res) ->
  person = res.match[1]
  try
    update_date(firebase, res, person.trim(), VALUE_OF_ELECTED)
  catch error
    res.send "update_date KO il faut appeler la maintenance" + error

update_croissant = (firebase, res) ->
  person = res.match[1]
  today = new Date()
  fulldate = today.getFullYear() + "/" + zero_pad( today.getMonth()+1 ) + "/" + zero_pad(today.getDate())
  try
    update_date(firebase, res, person.trim(), fulldate)
  catch error
    res.send "update_date KO il faut appeler la maintenance" +error
    res.send person + " existe t il ?"

quand_croissant = (firebase, res) ->
  person = res.match[1]
  res.http(firebase + "users.json?orderBy=\"login\"&equalTo=\""+person.trim()+"\"",
      {'agent':proxy(PROXY, false)}
    )
  .get() (err, res2, body) ->
   try
     json = JSON.parse(body)
     key = Object.keys(json)[0]
     res.send person + " apportera prochainement les croissants " if json[key].last is VALUE_OF_ELECTED
     res.send person + " a apporté les croissants le " + date_fr_format(json[key].last) unless json[key].last is VALUE_OF_ELECTED
   catch error
     res.send "KO il faut appeler la maintenance " + error
     res.send "Le compte " + person + " existe t-il ?"

list_croissant = (firebase, msg) ->
  msg.http(firebase + "users.json", {'agent':proxy(PROXY, false)} )
  .get() (err, res, body) ->
    try
      json = JSON.parse(body)
      values = Object.keys(json).map((key) => return json[key])
      msg.send "Voici la liste des personnes participantes :"
      msg.send "\t\t @#{obj.login} (#{obj.full_name})" for obj in values
    catch error
      msg.send "KO il faut appeler la maintenance" + error


module.exports = (robot) ->
#    gohome = new cronJob QUITTING_TIME,
#            ->
#              robot.messageRoom ROOM, "C'est le moment de choisir qui apportera les croissants !  Vite !"
#            null
#            true
#https://stackoverflow.com/questions/11196659/get-hubot-to-talk-at-a-certain-time
    robot.respond /Qui sont les plus forts ?/i, (msg) ->
      msg.send "Ce sont les Nantais, bien sûr!!! "

    robot.respond /croissant nantes liste/i, (msg) ->
      msg.send "A Nantes, "
      list_croissant(ROOT_FIREBASE_NANTES, msg)

    robot.respond /croissant toulouse liste/i, (msg) ->
      msg.send "A Toulouse, "
      list_croissant(ROOT_FIREBASE_TOULOUSE, msg)

    robot.respond /croissant nantes combien/i, (msg) ->
      msg.send "A Nantes, "
      combien_croissant(ROOT_FIREBASE_NANTES, msg)

    robot.respond /croissant toulouse combien/i, (msg) ->
      msg.send "A Toulouse, "
      combien_croissant(ROOT_FIREBASE_TOULOUSE, msg)

    robot.respond /croissant nantes qui/i, (msg) ->
      msg.send "A Nantes, "
      qui_croissant(ROOT_FIREBASE_NANTES, msg)

    robot.respond /croissant toulouse qui/i, (msg) ->
      msg.send "A Toulouse, "
      qui_croissant(ROOT_FIREBASE_TOULOUSE, msg)

    robot.respond /croissant nantes elu(.*)/i, (res) ->
      res.send "A Nantes, "
      elu_croissant(ROOT_FIREBASE_NANTES, res)

    robot.respond /croissant toulouse elu(.*)/i, (res) ->
      res.send "A Toulouse, "
      elu_croissant(ROOT_FIREBASE_TOULOUSE, res)

    robot.respond /croissant nantes update(.*)/i, (res) ->
      res.send "A Nantes, "
      update_croissant(ROOT_FIREBASE_NANTES, res)

    robot.respond /croissant toulouse update(.*)/i, (res) ->
      res.send "A Toulouse, "
      update_croissant(ROOT_FIREBASE_TOULOUSE, res)

    robot.respond /croissant nantes quand(.*)/i, (res) ->
      res.send "A Nantes, "
      quand_croissant(ROOT_FIREBASE_NANTES, res)

    robot.respond /croissant toulouse quand(.*)/i, (res) ->
      res.send "A Toulouse, "
      quand_croissant(ROOT_FIREBASE_TOULOUSE, res)

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
