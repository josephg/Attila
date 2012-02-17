
canvas = atom.canvas
ctx = atom.ctx

TAU = Math.PI * 2

rand = (x = 1) -> Math.random() * x
randInt = (x) -> Math.floor rand(x)

map = {}

getMap = (x, y) -> map["#{x},#{y}"]
setMap = (x, y, value) -> map["#{x},#{y}"] = value

units = []

canvas.width = 800
canvas.height = 600

addUnit = (unit) ->
  throw new Error 'asdf' if getMap(unit.x, unit.y)

  units.push unit
  setMap unit.x, unit.y, unit

  unit.added?()

  unit


class Town
  constructor: (@x, @y) ->
    @owner = 'neutral'
    @numUnits = 0

  added: ->
    @spawn() for [1..10]

  update: (dt) ->
    return if @numUnits > 10

    @spawn() unless randInt 60 * 10

  draw: ->
    ctx.fillStyle = 'black'
    ctx.fillRect @x * 5, @y * 5, 5, 5

  spawn: ->
    [x, y] = [@x + (randInt 5) - 2, @y + (randInt 5) - 2]
    u = addUnit new Unit(x, y) unless getMap x, y
    if u
      u.owner = this
      @numUnits++


class Unit
  constructor: (@x, @y) ->
    @phase = rand 0.5
    @owner = 'player'


  move: ->
    probability = if @owner is 'player'
      .25
    else
      if Math.abs(@x-@owner.x) < 5 and Math.abs(@y-@owner.y) < 5
        .9
      else
        .01

    [dx, dy] = if rand() < probability
      ([[-1,0],[0,-1],[1,0],[0,1]])[randInt 4]
    else
      if @owner is 'player'
        mx = atom.input.mouse.x/5
        my = (600 - atom.input.mouse.y)/5
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


    return if getMap @x+dx, @y+dy

    setMap @x, @y, undefined
    @x += dx
    @y += dy
    setMap @x, @y, this

  draw: ->
    ctx.fillStyle = (if @owner is 'player' then 'red' else 'grey')
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

    for [1..100]
      [x, y] = [randInt(160), randInt(120)]
      addUnit new Unit(x, y) unless getMap x, y

  update: (dt) ->
    dt = 1/60
    unit.update dt for unit in units

  draw: ->
    ctx.fillStyle = 'rgb(215,232,148)'
    ctx.fillRect 0, 0, 800, 600

    unit.draw() for unit in units



game = new Game()
game.run()

window.onblur = -> game.stop()
window.onfocus = -> game.run()
