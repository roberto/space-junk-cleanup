require 'gosu'

class Plane
  WIDTH = 66
  HEIGHT = 66
  attr_reader :lasers, :x, :y
  def initialize(sprite, x, y, laser_sprite)
    @sprite = sprite
    @laser_sprite = laser_sprite
    @current_sprite = 0
    @x, @y = x, y
    @last_shoot = Float::MIN
    @lasers = []
  end

  def active?
    true
  end

  def left
    if @x > WIDTH/2
      @x -= 10
    end
  end

  def right
    if @x < (600 - WIDTH/2)
      @x += 10
    end
  end

  def shoot
    if can_shoot?
      laser = Laser.new(@laser_sprite)
      @lasers << laser
      laser.go(@x, @y)
    end
  end

  def can_shoot?
    current_time = Gosu::milliseconds

    if current_time - @last_shoot > 100
      @last_shoot = current_time 
      true
    end
  end

  def update
    @lasers.each do |laser|
      if laser.active?
        laser.update
      else
        @lasers.delete(laser)
      end
    end
  end

  def draw
    @sprite[Gosu::milliseconds / 100 % @sprite.size].draw_rot(@x, @y, 1, 0)
    @lasers.each(&:draw)
  end
end

class Laser
  attr_reader :x, :y
  def initialize(sprite)
    @active = false
    @sprite = sprite
  end

  def go(x, y)
    @active = true
    @x, @y = x, y
  end

  def stop
    @active = false
  end

  def active?
    @active
  end

  def update
    if active?
      if @y < 0
        @active = false
      else
        @y -= 6
      end
    end
  end

  def draw
    @sprite.draw(@x, @y, 2) if active?
  end
end

class Asteroid
  attr_reader :x, :y

  def initialize(sprite)
    @sprite = sprite
    @x, @y = 0, 0
  end

  def go
    @moving = true
    @y = 0
    @x = Gosu.random(10, 590)
  end

  def active?
    @moving
  end

  def move
    @y += 3
  end

  def explode
    @moving = false
  end

  def update
    if @y > 600 || !@moving
      go
    else
      move
    end
  end

  def draw
    @sprite[Gosu::milliseconds / 50 % @sprite.size].draw_rot(@x, @y, 3, 0) if @moving
  end
end

class GameWindow < Gosu::Window
  def initialize
    super(600, 600, false)
    self.caption = 'Sky Cleanup'
    @background = Gosu::Image.new(self, "images/bg.png", true)
    planes_sprite = Gosu::Image.load_tiles(self, "images/planes.png", 66, 67, true)
    asteroids_sprite = Gosu::Image.load_tiles(self, "images/asteroids.png", 320/5, 384/6, true)
    laser_sprite = Gosu::Image.new(self, "images/laser.png", true)
    @plane = Plane.new(planes_sprite[0..2], 267, 530, laser_sprite)
    @asteroids = [Asteroid.new(asteroids_sprite), Asteroid.new(asteroids_sprite)]
    @font = Gosu::Font.new(self, Gosu::default_font_name, 50)
    @score = 0
    @active = true
  end

  def active?
    @active
  end

  def update
    if active?
      @plane.left   if button_down? Gosu::KbLeft
      @plane.right  if button_down? Gosu::KbRight
      @plane.shoot  if button_down? Gosu::KbUp
      @asteroids.each(&:update)
      @plane.update
      @asteroids.each do |asteroid|
        if collision?(@plane, asteroid, 40)
          @active = false
        end

        @plane.lasers.each do |laser|
          if collision?(laser, asteroid, 20)
            asteroid.explode
            laser.stop
            @score += 1
          end
        end
      end
    end
  end

  def collision?(a, b, distance)
    return false unless a.active? && b.active?
    Gosu::distance(a.x, a.y, b.x, b.y) < distance
  end

  def draw
    @background.draw(0,0,0)
    @plane.draw
    @asteroids.each(&:draw)
    @font.draw_rel(@score, 600, 0, 5, 1, 0)
    if !active?
      @font.draw_rel("GAME OVER!", 300, 300, 5, 0.5, 0.5)
    end
  end

  def button_down(id)
    if id == Gosu::KbEscape
      close
    end
  end
end

gwindow = GameWindow.new
gwindow.show
