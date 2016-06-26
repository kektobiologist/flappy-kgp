DEBUG = false
SPEED = 160
GRAVITY = 1100
FLAP = 320
SPAWN_RATE = 1 / 1200
OPENING = 100
SCALE = 1

HEIGHT = 384
# WIDTH = 288
WIDTH = 500
# HEIGHT = 576
# WIDTH = 1024*2
# GAME_HEIGHT = 336
GROUND_HEIGHT = 64
GROUND_Y = HEIGHT - GROUND_HEIGHT

parent = document.querySelector("#screen")
gameStarted = undefined
gameOver = undefined

deadTubeTops = []
deadTubeBottoms = []
deadInvs = []

hallChosen = false
bg = null
# credits = null
tubes = null
invs = null
bird = null
ground = null
hall = null
gameOverPanel = null

score = null
scoreText = null
instText = null
gameOverText = null

flapSnd = null
scoreSnd = null
hurtSnd = null
fallSnd = null
swooshSnd = null
hoverSnd = null
clickSnd = null

tubesTimer = null
spaceKey = null
numHalls = 12
buttonList = null
leaderboardButton = null
githubHtml = """<iframe src="http://ghbtns.com/github-btn.html?user=hyspace&repo=flappy&type=watch&count=true&size=large"
  allowtransparency="true" frameborder="0" scrolling="0" width="150" height="30"></iframe>"""

floor = Math.floor

main = ->
  spawntube = (openPos, flipped) ->
    tube = null

    tubeKey = if flipped then "tubeTop" else "tubeBottom"
    if flipped
      tubeY = floor(openPos - OPENING / 2 - 320)
    else
      tubeY = floor(openPos + OPENING / 2)

    if deadTubeTops.length > 0 and tubeKey == "tubeTop"
      tube = deadTubeTops.pop().revive()
      tube.reset(game.world.width, tubeY)
    else if deadTubeBottoms.length > 0 and tubeKey == "tubeBottom"
      tube = deadTubeBottoms.pop().revive()
      tube.reset(game.world.width, tubeY)
    else
      tube = tubes.create(game.world.width, tubeY, tubeKey)
      game.physics.arcade.enableBody(tube)
      tube.body.allowGravity = false

    # Move to the left
    tube.body.velocity.x = -SPEED
    tube

  spawntubes = ->
    # check dead tubes
    tubes.forEachAlive (tube) ->
      if tube.x + tube.width < game.world.bounds.left
        deadTubeTops.push tube.kill() if tube.key == "tubeTop"
        deadTubeBottoms.push tube.kill() if tube.key == "tubeBottom"
      return
    invs.forEachAlive (invs) ->
      deadInvs.push invs.kill() if invs.x + invs.width < game.world.bounds.left
      return

    tubeY = game.world.height / 2 + (Math.random()-0.5) * game.world.height * 0.2

    # Bottom tube
    bottube = spawntube(tubeY)

    # Top tube (flipped)
    toptube = spawntube(tubeY, true)

    # Add invisible thingy
    if deadInvs.length > 0
      inv = deadInvs.pop().revive().reset(toptube.x + toptube.width / 2, 0)
    else
      inv = invs.create(toptube.x + toptube.width / 2, 0)
      game.physics.arcade.enableBody(inv)
      inv.width = 2
      inv.height = game.world.height
      inv.body.allowGravity = false
    inv.body.velocity.x = -SPEED
    return

  addScore = (_, inv) ->
    invs.remove inv
    score += 1
    scoreText.setText score
    scoreSnd.play()
    return

  setGameOver = ->
    gameOver = true
    bird.body.velocity.y = 100 if bird.body.velocity.y > 0
    bird.animations.stop()
    bird.frame = 1
    instText.setText "TOUCH\nTO TRY AGAIN"
    instText.renderable = true
    hiscore = window.localStorage.getItem("hiscore")
    hiscore = (if hiscore then hiscore else score)
    hiscore = (if score > parseInt(hiscore, 10) then score else hiscore)
    window.localStorage.setItem "hiscore", hiscore
    gameOverText.setText "GAMEOVER\n\nHIGH SCORE\n\n" + hiscore
    gameOverText.renderable = true

    # Stop all tubes
    tubes.forEachAlive (tube) ->
      tube.body.velocity.x = 0
      return

    invs.forEach (inv) ->
      inv.body.velocity.x = 0
      return

    # Stop spawning tubes
    game.time.events.remove(tubesTimer)

    # show game over panel
    
    game.time.events.add 1000, ->
      gameOverPanel.revive()
      gameOverPanel.bringToTop()
      tween = game.add.tween(gameOverPanel).to(y:game.world.height / 2, 800, Phaser.Easing.Back.Out,true);
      tween.onComplete.add ->
        fn = ->
          if gameOverPanel.alive
            tween = game.add.tween(gameOverPanel).to(y:game.world.height * 1.5, 800, Phaser.Easing.Back.In, true);
            swooshSnd.play()
            # remove events heere as well, jsut to remove weird sounds. doesn't affect gameplay
            spaceKey.onDown.removeAll()
            bg.events.onInputDown.removeAll()
            tween.onComplete.add ->
              gameOverPanel.kill()
              reset()
              # swooshSnd.play()
          else
            reset()
            # swooshSnd.play()
        bg.events.onInputDown.addOnce fn
        spaceKey.onDown.addOnce fn
      swooshSnd.play()

    # Make bird reset the game
    # game.time.events.add 1000, ->
      

    hurtSnd.play()
    return

  flap = ->
    start()  unless gameStarted
    unless gameOver
      # bird.body.velocity.y = -FLAP
      bird.body.gravity.y = 0;
      bird.body.velocity.y = -100;
      tween = game.add.tween(bird.body.velocity).to(y:-FLAP, 25, Phaser.Easing.Bounce.In,true);
      tween.onComplete.add ->
        bird.body.gravity.y = GRAVITY
      flapSnd.play()
    return

  preload = ->
    for num in [1..numHalls]
      birdname = "bird" + num
      game.load.spritesheet birdname, "assets/birds/" + birdname + ".png", 36, 26
      btnname = "button" + num
      game.load.spritesheet btnname, "assets/buttons/" + btnname + ".png", 36, 26

    # game.load.bitmapFont('flappyfont', 'assets/fonts/flappyfont/flappyfont.png', 'assets/fonts/flappyfont/flappyfont.xml');
    # game.load.bitmapFont('flappyfont', 'assets/fonts/flappyfont/flappyfont.png', 'assets/fonts/flappyfont/flappyfont.fnt');
    # game.load.physics('birdphysics', 'assets/birds/bird.json');

    assets =
      physics:
        birdphysics: ['assets/birds/bird.json']

      bitmapFont:
        flappyfont: ['assets/fonts/flappyfont/flappyfont.png', 'assets/fonts/flappyfont/flappyfont.fnt']

      spritesheet:
        bird: [
          "assets/bird.png"
          36
          26
        ]

      image:
        tubeTop: ["assets/tube1.png"]
        tubeBottom: ["assets/tube2.png"]
        ground: ["assets/path.png"]
        bg: ["assets/bg2.png"]
        hall: ["assets/hall.png"]
        gameover: ["assets/gameover-panel.png"]
        leaderboardButton: ["assets/leaderboard.png"]

      audio:
        flap: ["assets/sfx_wing.mp3"]
        score: ["assets/sfx_point.mp3"]
        hurt: ["assets/sfx_hit.mp3"]
        fall: ["assets/sfx_die.mp3"]
        swoosh: ["assets/sfx_swooshing.mp3"]
        click: ["assets/keyboard_tap.mp3"]
        hover: ['assets/typewriter_key.mp3']

    Object.keys(assets).forEach (type) ->
      Object.keys(assets[type]).forEach (id) ->
        game.load[type].apply game.load, [id].concat(assets[type][id])
        return

      return

    return

  create = ->

    # enabling physics. don't know if necessary or not?
    game.physics.startSystem(Phaser.Physics.ARCADE);

    console.log("%chttps://github.com/hyspace/flappy", "color: black; font-size: x-large");
    ratio = window.innerWidth / window.innerHeight
    document.querySelector('#github').innerHTML = githubHtml if ratio > 1.15 or ratio < 0.7
    document.querySelector('#loading').style.display = 'none'

    # Set world dimensions
    Phaser.Canvas.setSmoothingEnabled(game.context, false)
    game.scaleMode = Phaser.ScaleManager.SHOW_ALL
    # game.scale.setScreenSize(true)
    game.world.width = WIDTH
    game.world.height = HEIGHT

    # Draw bg
    bg = game.add.tileSprite(0, 0, WIDTH, HEIGHT, 'bg')
    # enable input. now put all global mouse events on bg.
    bg.inputEnabled = true;
    bg.input.priorityID = 0; # lower priority
    # dummy bird
    bird = game.add.sprite(0, 0)
    # Credits 'yo
    # credits = game.add.text(game.world.width / 2, HEIGHT - GROUND_Y + 50, "",
    #   font: "8px \"Press Start 2P\""
    #   fill: "#fff"
    #   stroke: "#430"
    #   strokeThickness: 4
    #   align: "center"
    # )
    # credits.anchor.x = 0.5


    # # Add clouds group
    # clouds = game.add.group()

    # Add tubes
    tubes = game.add.group()

    # Add invisible thingies
    invs = game.add.group()

    

    # Add ground
    ground = game.add.tileSprite(0, GROUND_Y, WIDTH, GROUND_HEIGHT, "ground")
    ground.tileScale.setTo SCALE, SCALE

    # Add score text
    scoreText = game.add.text(game.world.width / 2, game.world.height / 4, "",
      font: "16px \"Press Start 2P\""
      fill: "#fff"
      stroke: "#430"
      strokeThickness: 4
      align: "center"
    )
    scoreText.anchor.setTo 0.5, 0.5

    # Add instructions text
    instText = game.add.text(game.world.width / 2, game.world.height - game.world.height / 4, "",
      font: "8px \"Press Start 2P\""
      fill: "#fff"
      stroke: "#430"
      strokeThickness: 4
      align: "center"
    )
    instText.anchor.setTo 0.5, 0.5

    # Add game over text
    gameOverText = game.add.text(game.world.width / 2, game.world.height / 2, "",
      font: "16px \"Press Start 2P\""
      fill: "#fff"
      stroke: "#430"
      strokeThickness: 4
      align: "center"
    )
    gameOverText.anchor.setTo 0.5, 0.5
    gameOverText.scale.setTo SCALE, SCALE
  
    # game over panel
    gameOverPanel = game.add.sprite(game.world.width/2, game.world.height * 1.5, "gameover" )
    gameOverPanel.anchor.setTo 0.5, 0.5
    gameOverPanel.kill()
    leaderboardButton = game.add.button 0, 0, 'leaderboardButton', ->
      # bg.events.onInputDown.removeAll()
      {}
      # tween = game.add.tween(gameOverPanel).to(y:game.world.height * 1.5, 800, Phaser.Easing.Back.In, true);
      # swooshSnd.play()
      # tween.onComplete.add ->
      #   gameOverPanel.kill()
    , this
    leaderboardButton.anchor.setTo 0.5, 0.5

    gameOverPanel.addChild leaderboardButton
    # hallTitleText = game.add.bitmapText(0, 0, 'flappyfont', "Choose your Hall bruh", 16, 'center');
    # hallTitleText = game.add.bitmapText(this.game.width/2, 10, 'flappyfont', "Hello World", 24);
    # hallTitleText.anchor.setTo 0.5, 0.5
    # hallTitleText.visible = true;

    # Add sounds
    flapSnd = game.add.audio("flap")
    flapSnd.allowMultiple = true
    scoreSnd = game.add.audio("score")
    hurtSnd = game.add.audio("hurt")
    fallSnd = game.add.audio("fall")
    swooshSnd = game.add.audio("swoosh")
    hoverSnd = game.add.audio("hover")
    clickSnd = game.add.audio("click")

    # bird is kill
    bird.kill()
    buttonList = []
    chooseHall()
    return

  chooseHall = ->
    # something
    console.log("choosing hall...")
    # add hall screen
    swooshSnd.play()
    hall = game.add.sprite(game.world.width/2, game.world.height * 1.5, "hall")
    hall.anchor.setTo 0.5, 0.5
    avWidth = hall.width - 50
    avHeight = hall.height - 100
    for num in [1..numHalls]
      num -= 1
      i = parseInt(num/4);
      j = num%4
      offx = -hall.width/2 + 72; 
      offy = -hall.height/2 + 120
      x = Math.round(avWidth/4*j + offx)
      y = Math.round(avHeight/3*i + offy)
      hall.addChild addButton(x, y, num+1)

    # hall.addChild buttonGroup
    # button = game.add.button 0, 0, 'bird', ->
    #   console.log('hey')
    # , this, 2, 1, 0
    # hall.addChild button
    # button.bringToTop
    tween = game.add.tween(hall).to(y:game.world.height / 2, 800, Phaser.Easing.Back.Out,true);

    
    # game.time.events.add 2000, ->
    #   # hide hall screen
    #   tween = game.add.tween(hall).to(y:game.world.height * 1.5, 800, Phaser.Easing.Back.In, true);
    #   tween.onComplete.add ->
    #     hall.kill()
    #   postHall()

  addButton = (x, y, idx) ->
    button = game.add.button x, y, 'button' + idx, ->
      postHall(idx) unless hallChosen
    , this, 2, 1, 0, 1
    button.anchor.setTo 0.5, 0.5
    # console.log('added btton at' + x + y)
    button.animations.add "onHover", [
      0
      1
      2
      1
    ], 10, true
    button.trueY = y
    # using click for hover, and swoosh for click...
    button.setOverSound(clickSnd)
    button.setUpSound(swooshSnd)
    button.events.onInputOver.add ->
      button.play("onHover", 10, true, false)
      button.doBounce = true
    button.events.onInputOut.add ->
      button.animations.stop()
      button.doBounce = false
    button.doBounce = false
    buttonList.push(button)
    button


  # call this after hall is chosen, to set up game/keys 
  postHall = (idx)->
    console.log('chose hall' + idx)
    hallChosen = true
    for button in buttonList
      button.setOverSound(null)
      button.setUpSound(null)
    # Add bird
    bird = game.add.sprite(0, 0, "bird" + idx)
    game.physics.arcade.enableBody(bird)
    hall.bringToTop()
    bird.anchor.setTo 0.5, 0.5
    bird.animations.add "fly", [
      0
      1
      2
      1
    ], 10, true
    bird.body.collideWorldBounds = true

    # can't use polygons in arcade physics..
    # bird.body.setPolygon(
    #   24,1,
    #   34,16,
    #   30,32,
    #   20,24,
    #   12,34,
    #   2,12,
    #   14,2
    # )

    # disable all the buttons?
    tween = game.add.tween(hall).to(y:game.world.height * 1.5, 800, Phaser.Easing.Back.In, true);
    tween.onComplete.add ->
      for button in buttonList
        button.destroy()
      hall.destroy()
    # revive bird
    bird.revive()

    # Add controls
    spaceKey = game.input.keyboard.addKey(Phaser.Keyboard.SPACEBAR)
    spaceKey.onDown.add flap
    bg.events.onInputDown.add flap
    bg.events.onInputDown.add ->
      console.log("down pressed?")
    # RESET!
    reset()

  reset = ->
    spaceKey.onDown.removeAll()
    bg.events.onInputDown.removeAll()
    spaceKey.onDown.add flap    
    bg.events.onInputDown.add flap
    gameStarted = false
    gameOver = false
    score = 0
    # credits.renderable = true
    # credits.setText "see console log\nfor github url"
    scoreText.setText "Flappy Bird 2.2 Edition"
    instText.setText "TOUCH TO FLY\nFLAP bird WINGS"
    gameOverText.renderable = false
    bird.body.allowGravity = false
    bird.reset game.world.width * 0.3, game.world.height / 2
    bird.angle = 0
    bird.animations.play "fly"
    tubes.removeAll()
    invs.removeAll()
    return

  start = ->
    # console.log("start called")
    # START!
    gameStarted = true
    # remove timer here for good measure. luckily doesn't break even if already removed
    game.time.events.remove(tubesTimer)
    # credits.renderable = false
    bird.body.allowGravity = true
    bird.body.gravity.y = GRAVITY

    # SPAWN tubeS!
    tubesTimer = game.time.events.loop 1 / SPAWN_RATE, spawntubes


    # Show score
    scoreText.setText score
    instText.renderable = false

    return

  update = ->
    if gameStarted
      if !gameOver
        # Make bird dive
        bird.angle = (90 * (FLAP + bird.body.velocity.y) / FLAP) - 180
        bird.angle = -30  if bird.angle < -30
        if bird.angle > 80
          bird.angle = 90
          bird.animations.stop()
          bird.frame = 1
        else
          bird.animations.play()

        # Check game over
        game.physics.arcade.overlap bird, tubes, ->
          setGameOver()
          fallSnd.play()
        setGameOver() if not gameOver and bird.body.bottom >= GROUND_Y

        # Add score
        game.physics.arcade.overlap bird, invs, addScore

      else
        # rotate the bird to make sure its head hit ground
        tween = game.add.tween(bird).to(angle: 90, 100, Phaser.Easing.Bounce.Out, true);
        if bird.body.bottom >= GROUND_Y + 3
          bird.y = GROUND_Y - 13
          bird.body.velocity.y = 0
          bird.body.allowGravity = false
          bird.body.gravity.y = 0

    else
      bird.y = (game.world.height / 2) + 8 * Math.cos(game.time.now / 200)
      bird.angle = 0

    if !hallChosen
      for button in buttonList
        if button.doBounce
          button.y = button.trueY + 5 * Math.cos(game.time.now / 200)
        else
          button.y = button.trueY
   

    # Scroll ground
    bg.tilePosition.x -= game.time.physicsElapsed * SPEED/5 unless gameOver
    ground.tilePosition.x -= game.time.physicsElapsed * SPEED unless gameOver
    return

  render = ->
    if DEBUG
      game.debug.renderSpriteBody bird
      tubes.forEachAlive (tube) ->
        game.debug.renderSpriteBody tube
        return

      invs.forEach (inv) ->
        game.debug.renderSpriteBody inv
        return

    return

  state =
    preload: preload
    create: create
    update: update
    render: render

  game = new Phaser.Game(WIDTH, HEIGHT, Phaser.CANVAS, parent, state, false, false)
  # Phaser.Canvas.setSmoothingEnabled(game.context, false);
  return

WebFontConfig =
  google:
    families: [ 'Press+Start+2P::latin' ]
  active: main
(->
  wf = document.createElement('script')
  wf.src = (if 'https:' == document.location.protocol then 'https' else 'http') +
    '://ajax.googleapis.com/ajax/libs/webfont/1/webfont.js'
  wf.type = 'text/javascript'
  wf.async = 'true'
  s = document.getElementsByTagName('script')[0]
  s.parentNode.insertBefore(wf, s)
)()