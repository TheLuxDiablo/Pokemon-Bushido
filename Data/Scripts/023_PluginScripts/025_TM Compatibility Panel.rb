class TMCompatibilityPanel < SpriteWrapper
  attr_accessor :move

  def initialize(viewport = nil)
    super(viewport)
    @sprites = {}
    @move    = 0
    $Trainer.party.each_with_index do |p, i|
      @sprites["pkmn_#{i}"]   = PokemonIconSprite.new(p, viewport)
      @sprites["pkmn_#{i}"].setOffset(PictureOrigin::Center)
    end
  end

  def update
    super
    $Trainer.party.each_with_index do |p, i|
      sprite = @sprites["pkmn_#{i}"]
      sprite.color   = self.color
      sprite.opacity = self.opacity
      sprite.visible = self.visible
      sprite.update
      sprite.z       = self.z + 1
      sprite.x       = self.x + ((self.src_rect.width / 6).floor * ((2 * (i % 3)) + 1)) + [4, 0, -4][i % 3]
      sprite.y       = self.y + ((self.src_rect.height / 4).floor * ((2 * (i % 2)) + 1)) + 8
      next if @move <= 0
      sprite.tone.gray = (sprite.pokemon.able? && sprite.pokemon.compatibleWithMove?(@move) ? 0 : 255)
    end
  end

  def dispose
    super
    pbDisposeSpriteHash(@sprites)
  end
end
