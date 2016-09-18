require "scorched_earth/helpers"
require "scorched_earth/terrain"
require "scorched_earth/player"
require "scorched_earth/shot"
require "scorched_earth/mouse"
require "scorched_earth/color_palette"

module ScorchedEarth
  class GameScene < Ray::Scene
    include Helpers

    attr_reader :color_palette, :entities, :mouse, :players, :terrain

    def register
      mouse.register self

      add_hook :key_press, key(:escape), method(:exit!)

      on(:entity_created) { |entity| entities << entity }

      always do
        update
      end
    end

    def setup
      width, height  = *window.size
      @color_palette = ColorPalette.new(Ray::Color.red, Ray::Color.yellow, Ray::Color.white)
      @entities      = []
      @players       = 2.times.map { |index| Player.new rand(width), color_palette.get("player_#{index}") }
      @terrain       = Terrain.new width, height, rand(10), color_palette.get("terrain")
      @mouse         = Mouse.new(terrain, players)
    end

    def update
      radius = 50
      @entities.each { |entity| entity.update 1.0 / frames_per_second }
      @entities, @dead = *@entities.partition { |entity| entity.y > terrain.fetch(entity.x, 0) }
      @dead
        .select { |entity| entity.x < terrain.width && entity.x > 0 }
        .each   { |entity| terrain.bite(entity.x, radius) }
        .select { |entity| players.any? { |player| inside_radius?(entity.x - player.x, 0, radius) } }
        .each   { pop_scene and push_scene @scene_name }
    end

    def render(win)
      win.clear color_palette.get("sky")

      players.each do |player|
        player.draw win, terrain[player.x]
      end

      mouse.draw win

      terrain.draw win

      entities.each do |entity|
        entity.draw win
      end
    end
  end
end