
canvas = atom.canvas
ctx = atom.ctx

TAU = Math.PI * 2

rand = (x = 1) -> Math.random() * x
randInt = (x) -> Math.floor rand(x)

map = {}

getMap = (x, y) -> map["#{x},#{y}"]
setMap = (x, y, value) ->
  if value?
    map["#{x},#{y}"] = value
  else
    delete map["#{x},#{y}"]

units = []
deadUnits = []

canvas.width = 800
canvas.height = 600

addUnit = (unit) ->
  throw new Error 'asdf' if getMap(unit.x, unit.y)

  units.push unit
  setMap unit.x, unit.y, unit

  unit.added?()

  unit

hsl = (h, s, l) -> (a = 1) -> "hsla(#{h},#{s*100}%,#{l*100}%,#{a})"
cursors = [{x:200, y:100}, {x:600, y:500}]
colors = [hsl(0,1,0.5), hsl(180,1,0.8)]

cursorGrid = (p) -> [Math.floor(cursors[p].x)/5, (600 - Math.floor(cursors[p].y))/5]

class Town
  constructor: (@x, @y, @owner = 'neutral') ->
    @numUnits = 0
    @hp = 20

  added: ->
    @spawn() for [1..10]

  update: (dt) ->
    return if @numUnits >= 10

    @spawn() unless randInt 60 * 10

  draw: ->
    ctx.fillStyle = (if typeof @owner is 'number' then colors[@owner](0.8) else 'black')
    ctx.fillRect @x * 5, @y * 5, 5, 5

  spawn: ->
    [x, y] = [@x + (randInt 5) - 2, @y + (randInt 5) - 2]
    u = addUnit new Unit(x, y, @owner, this) unless getMap x, y
    if u
      @numUnits++
      u.followCursor = false

  die: (killer) ->
    @owner = killer.owner
    for u in units when u.town is this
      u.owner = 'neutral'
      u.town = null

    @hp = 20
    @numUnits = 0
    #console.error 'town died'

class Unit
  constructor: (@x, @y, @owner, @town) ->
    @phase = rand 0.5
    @hp = 3
    @followCursor = true

  move: ->
    # Probability of moving randomly
    probability = if @owner isnt 'neutral' and @followCursor # player
      .25
    else if @town
      if Math.abs(@x-@town.x) < 5 and Math.abs(@y-@town.y) < 5
        .9
      else
        .01
    else
      1

    [dx, dy] = if rand() < probability
      ([[-1,0],[0,-1],[1,0],[0,1]])[randInt 4]
    else
      if @followCursor
        [mx, my] = cursorGrid @owner
      else if @town
        [mx, my] = [@town.x, @town.y]
      else
        throw new Error 'NOT OK'

      theta = Math.atan2 (my-@y), (mx-@x)
      px = Math.cos theta
      if rand() < px*px
        # move on x axis
        if mx > @x then [1,0] else [-1,0]
      else
        # move on y axis
        if my > @y then [0,1] else [0,-1]


    
    u = getMap @x+dx, @y+dy
    if u
      if u instanceof Town # Attack a town
        if u.owner is @owner
          @hp = Math.min @hp+1, 3
        else
          @attack u
          console.log u.hp

      else # Attack a unit
        if @owner isnt 'neutral' and u.owner is @owner and @followCursor
          u.followCursor = true

        else if u.owner != @owner
          # Not one of my guys
          @attack u

    else
      # Move
      setMap @x, @y, undefined
      @x += dx
      @y += dy
      setMap @x, @y, this

  attack: (u) ->
    u.hp--
    if u.hp is 0
      u.die this

  die: ->
    deadUnits.push this
    @dead = true
    @town.numUnits-- if @town

  draw: ->
    ctx.fillStyle = (if typeof @owner is 'number' then colors[@owner](@hp/3) else 'grey')
    ctx.fillRect @x*5, @y*5, 5, 5

  update: (dt) ->
    @phase -= dt

    if @phase <= 0
      @move()

      @phase += 0.1

class Game extends atom.Game
  constructor: ->
    super()
    ctx.translate 0, 600
    ctx.scale 1, -1

    for owner in [0, 1]
      [mx, my] = cursorGrid owner
      addUnit new Town(mx, my, owner)

    unit.followCursor = true for unit in units

    for [1..5]
      [x, y] = [randInt(160), randInt(120)]
      addUnit new Town(x, y) unless getMap x, y


  update: (dt) ->
    dt = 1/60

    cursorSpeed = 120 * dt
    if atom.input.down 'p1left'
      cursors[0].x -= cursorSpeed
    if atom.input.down 'p1right'
      cursors[0].x += cursorSpeed
    if atom.input.down 'p1up'
      cursors[0].y -= cursorSpeed
    if atom.input.down 'p1down'
      cursors[0].y += cursorSpeed

    if atom.input.down 'p2left'
      cursors[1].x -= cursorSpeed
    if atom.input.down 'p2right'
      cursors[1].x += cursorSpeed
    if atom.input.down 'p2up'
      cursors[1].y -= cursorSpeed
    if atom.input.down 'p2down'
      cursors[1].y += cursorSpeed


    unit.update dt for unit in units

    for u in deadUnits
      i = units.indexOf u
      units[i] = units[units.length - 1]
      units.length--

      setMap u.x, u.y, undefined

    deadUnits.length = 0


  draw: ->
    ctx.fillStyle = 'rgb(215,232,148)'
    ctx.fillRect 0, 0, 800, 600

    unit.draw() for unit in units

    @drawCursor c, i for c, i in cursors

  drawCursor: (c, i) ->
    ctx.save()
    ctx.scale 1, -1
    ctx.translate 0, -600
    ctx.fillStyle = if i == 0 then 'red' else 'blue'
    r = 6
    ctx.fillRect c.x-r, c.y, r-2, 2
    ctx.fillRect c.x+4, c.y, r-2, 2
    ctx.fillRect c.x, c.y-r, 2, r-2
    ctx.fillRect c.x, c.y+4, 2, r-2
    ctx.restore()

 
atom.input.bind atom.key.LEFT_ARROW, 'p1left'
atom.input.bind atom.key.RIGHT_ARROW, 'p1right'
atom.input.bind atom.key.UP_ARROW, 'p1up'
atom.input.bind atom.key.DOWN_ARROW, 'p1down'

atom.input.bind atom.key.W, 'p2up'
atom.input.bind atom.key.A, 'p2left'
atom.input.bind atom.key.S, 'p2down'
atom.input.bind atom.key.D, 'p2right'

game = new Game()
game.run()

window.onblur = -> game.stop()
window.onfocus = -> game.run()

