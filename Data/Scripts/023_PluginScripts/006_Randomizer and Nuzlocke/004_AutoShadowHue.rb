# Resolves the graphic filename for the shadow pattern overlay
def pbResolveShadowPattern(icon = false)
  if icon && pbResolveBitmap("Graphics/Pictures/Battle/shadow_pattern_icon")
    return "Graphics/Pictures/Battle/shadow_pattern_icon"
  end
  return "Graphics/Pictures/Battle/shadow_pattern" if pbResolveBitmap("Graphics/Pictures/Battle/shadow_pattern")
  return nil
end

# Utility for checking if the Shadow pattern can be used on a Pokemon
def pbCanUseShadowPattern?(pokemon, icon = false)
  return false if !pokemon || !pokemon.shadowPokemon?
  return false if !pbResolveShadowPattern(icon)
  if !icon
    try_form, try_gender = [""], [""]
    try_form.insert(0, sprintf("_%d", pokemon.form)) if pokemon.form && pokemon.form > 0
    try_gender.insert(0, "_female") if pokemon.gender == 1 rescue nil
    try_form.each do |f|
      try_gender.each do |g|
        try_file = sprintf("Graphics/Battlers/%03d%s%s_shadow", pokemon.species, f, g) rescue nil
        return false if try_file && pbResolveBitmap(try_file)
        try_file2 = sprintf("Graphics/Pokemon/Front/%s%s%s_shadow", pokemon.species, f, g) rescue nil
        return false if try_file2 && pbResolveBitmap(try_file2)
      end
    end
  else
    try_form, try_gender = [""], [""]
    try_form.insert(0, sprintf("_%d", pokemon.form)) if pokemon.form && pokemon.form > 0
    try_gender.insert(0, "_female") if pokemon.gender == 1 rescue nil
    try_form.each do |f|
      try_gender.each do |g|
        try_file = sprintf("Graphics/Icons/icon%03d%s%s_shadow", pokemon.species, f, g) rescue nil
        return false if try_file && pbResolveBitmap(try_file)
      end
    end
  end
  return true
end

# Sprite methods for Shadow pattern overlay
class Sprite
  attr_accessor :pattern_type

  def apply_shadow_pattern(pokemon, subfolder = "Front")
    is_icon = (subfolder == "Icons")
    pattern_file = pbResolveShadowPattern(is_icon)
    return if !pattern_file
    if pbCanUseShadowPattern?(pokemon, is_icon)
      self.pattern = Bitmap.new(pattern_file)
      self.pattern_opacity = 150
      self.pattern_type = :shadow
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end

  def set_shadow_pattern(pokemon)
    if pokemon && pokemon.shadowPokemon?
      apply_shadow_pattern(pokemon, "Front")
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end

  def set_shadow_icon_pattern(pokemon = nil)
    pkmn = pokemon || (self.respond_to?(:pokemon) ? self.pokemon : nil)
    if pkmn && pkmn.shadowPokemon?
      apply_shadow_pattern(pkmn, "Icons")
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end

  def update_shadow_pattern
    return if self.pattern_type != :shadow
    freq = [Graphics.frame_rate / 20, 1].max
    if (Graphics.frame_count % freq) == 0
      self.pattern_scroll_y -= 1 if self.pattern
    end
    # Lock pattern X offset to current src_rect.x to prevent blinking during multi-frame animations
    if self.respond_to?(:src_rect) && self.src_rect && self.pattern
      self.pattern_scroll_x = -self.src_rect.x
    end
  end

  def set_plugin_pattern(pokemon, override = false)
    set_shadow_pattern(pokemon)
  end

  def set_plugin_icon_pattern(pokemon = nil)
    set_shadow_icon_pattern(pokemon)
  end

  def update_plugin_pattern
    update_shadow_pattern
  end
end

# SpriteWrapper pattern properties
class SpriteWrapper
  def pattern;               @sprite.pattern rescue nil;               end
  def pattern=(value);       @sprite.pattern = value rescue nil;       end
  def pattern_opacity;       @sprite.pattern_opacity rescue 255;       end
  def pattern_opacity=(val); @sprite.pattern_opacity = val rescue nil; end
  def pattern_scroll_x;      @sprite.pattern_scroll_x rescue 0;        end
  def pattern_scroll_x=(v);  @sprite.pattern_scroll_x = v rescue nil;  end
  def pattern_scroll_y;      @sprite.pattern_scroll_y rescue 0;        end
  def pattern_scroll_y=(v);  @sprite.pattern_scroll_y = v rescue nil;  end
  def pattern_type;          @sprite.pattern_type rescue nil;          end
  def pattern_type=(val);    @sprite.pattern_type = val rescue nil;    end

  def apply_shadow_pattern(pokemon, subfolder = "Front")
    @sprite.apply_shadow_pattern(pokemon, subfolder) if @sprite
  end

  def set_shadow_pattern(pokemon)
    @sprite.set_shadow_pattern(pokemon) if @sprite
  end

  def set_shadow_icon_pattern(pokemon = nil)
    pkmn = pokemon || (self.respond_to?(:pokemon) ? self.pokemon : (@pokemon rescue nil))
    @sprite.set_shadow_icon_pattern(pkmn) if @sprite
  end

  def update_shadow_pattern
    if @sprite
      @sprite.update_shadow_pattern
      if @sprite.respond_to?(:src_rect) && @sprite.src_rect && @sprite.pattern
        @sprite.pattern_scroll_x = -@sprite.src_rect.x
      end
    end
  end

  def set_plugin_pattern(pokemon, override = false)
    @sprite.set_plugin_pattern(pokemon, override) if @sprite
  end

  def set_plugin_icon_pattern(pokemon = nil)
    pkmn = pokemon || (self.respond_to?(:pokemon) ? self.pokemon : (@pokemon rescue nil))
    @sprite.set_plugin_icon_pattern(pkmn) if @sprite
  end

  def update_plugin_pattern
    update_shadow_pattern
  end

  alias shadow_viewport= viewport= unless method_defined?(:shadow_viewport=)
  def viewport=(value)
    self.shadow_viewport = value
    if instance_variable_defined?(:@pokemon) && @pokemon && @pokemon.shadowPokemon?
      self.set_shadow_icon_pattern(@pokemon)
    end
  end
end

# Aliased to set Shadow pattern on battler sprites
class PokemonBattlerSprite < RPG::Sprite
  alias shadow_setPokemonBitmap setPokemonBitmap unless method_defined?(:shadow_setPokemonBitmap)
  def setPokemonBitmap(pkmn, back = false)
    shadow_setPokemonBitmap(pkmn, back)
    self.set_shadow_pattern(pkmn)
  end

  alias shadow_update update unless method_defined?(:shadow_update)
  def update(frameCounter = 0)
    shadow_update(frameCounter)
    return if !@_iconBitmap
    self.update_shadow_pattern
  end
end

# Aliased to set Shadow pattern on species sprites (Summary / Dex)
class PokemonSprite < SpriteWrapper
  alias shadow_setPokemonBitmap setPokemonBitmap unless method_defined?(:shadow_setPokemonBitmap)
  def setPokemonBitmap(pokemon, back = false)
    shadow_setPokemonBitmap(pokemon, back)
    self.set_shadow_pattern(pokemon)
  end

  alias shadow_setPokemonBitmapSpecies setPokemonBitmapSpecies unless method_defined?(:shadow_setPokemonBitmapSpecies)
  def setPokemonBitmapSpecies(pokemon, species, back = false)
    shadow_setPokemonBitmapSpecies(pokemon, species, back)
    self.set_shadow_pattern(pokemon)
  end

  alias shadow_update update unless method_defined?(:shadow_update)
  def update
    shadow_update
    self.update_shadow_pattern
  end
end

# Aliased to set Shadow pattern on species icons (Party Screen / Dex)
class PokemonIconSprite < SpriteWrapper
  alias shadow_pokemon= pokemon= unless method_defined?(:shadow_pokemon=)
  def pokemon=(value)
    self.shadow_pokemon = value
    if @pokemon && @pokemon.shadowPokemon?
      self.set_shadow_icon_pattern(@pokemon)
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end

  alias shadow_update update unless method_defined?(:shadow_update)
  def update
    shadow_update
    self.update_shadow_pattern
  end
end

# Aliased to set Shadow pattern on storage icons (PC Storage)
class PokemonBoxIcon < IconSprite
  alias shadow_refresh refresh unless method_defined?(:shadow_refresh)
  def refresh
    shadow_refresh
    if @pokemon && @pokemon.shadowPokemon?
      self.set_shadow_icon_pattern(@pokemon)
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end

  alias shadow_update update unless method_defined?(:shadow_update)
  def update
    shadow_update
    self.update_shadow_pattern
  end
end

# Updates Shadow pattern on battler sprites in battle scene
class PokeBattle_Scene
  alias shadow_pbChangePokemon pbChangePokemon unless method_defined?(:shadow_pbChangePokemon)
  def pbChangePokemon(idxBattler, pkmn)
    shadow_pbChangePokemon(idxBattler, pkmn)
    battler = (idxBattler.respond_to?(:index)) ? idxBattler : @battle.battlers[idxBattler]
    pkmnSprite = @sprites["pokemon_#{battler.index}"]
    pkmnSprite.set_shadow_pattern(battler.pokemon) if pkmnSprite
  end
end

PluginManager.register({
  :name    => "Auto Shadow Hue",
  :version => "1.0",
  :credits => ["Lucidious89"]
})
