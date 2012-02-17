
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

cursors = [{x:200, y:100}, {x:600, y:500}]
colors = ['red', 'blue']

cursorGrid = (p) -> [Math.floor(cursors[p].x)/5, (600 - Math.floor(cursors[p].y))/5]

class Town
  constructor: (@x, @y) ->
    @owner = this
    @numUnits = 0
    @hp = 50

  added: ->
    @spawn() for [1..10]

  update: (dt) ->
    return if @numUnits > 10

    @spawn() unless randInt 60 * 10

  draw: ->
    ctx.fillStyle = (if typeof @owner is 'number' then colors[@owner] else 'black')
    ctx.fillRect @x * 5, @y * 5, 5, 5

  spawn: ->
    [x, y] = [@x + (randInt 5) - 2, @y + (randInt 5) - 2]
    u = addUnit new Unit(x, y, this) unless getMap x, y
    if u
      @numUnits++

  die: (killer) ->
    @owner = killer.owner
    @hp = 50


class Unit
  constructor: (@x, @y, @owner) ->
    @phase = rand 0.5
    @hp = 3

  move: ->
    probability = if typeof @owner is 'number' # player
      .25
    else
      if Math.abs(@x-@owner.x) < 5 and Math.abs(@y-@owner.y) < 5
        .9
      else
        .01

    [dx, dy] = if rand() < probability
      ([[-1,0],[0,-1],[1,0],[0,1]])[randInt 4]
    else
      if typeof @owner is 'number'
        [mx, my] = cursorGrid @owner
      else
        mx = @owner.x
        my = @owner.y

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
      # Maybe attack
      
      if u.owner != @owner
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
    if @owner instanceof Town
      @owner.numUnits--

  draw: ->
    ctx.fillStyle = (if typeof @owner is 'number' then colors[@owner] else 'grey')
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

    for [1..3]
      [x, y] = [randInt(160), randInt(120)]
      addUnit new Town(x, y) unless getMap x, y

    for owner in [0, 1]
      for [1..20]
        [mx, my] = cursorGrid owner
        [x, y] = [mx + (randInt 15) - 2, my + (randInt 15) - 2]
        addUnit new Unit(x, y, owner) unless getMap x, y

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
