def drawShadowPoke(bitmap,color=nil)
  blankcolor  = bitmap.get_pixel(0,0)
  shadowcolor = (color ? color : blankcolor)
  colorlayer  = Bitmap.new(bitmap.width,bitmap.height)
  colorlayer.fill_rect(colorlayer.rect, shadowcolor)
  bitmap.blt(0,0,colorlayer,colorlayer.rect,113)
  shadowcolor = bitmap.get_pixel(0,0)
  for x in 0...bitmap.width
    for y in 0...bitmap.height
      if bitmap.get_pixel(x,y) == shadowcolor
        bitmap.set_pixel(x,y,blankcolor)
      end
    end
  end
end

alias _shadow_pbLoadPokemonBitmapSpecies pbLoadPokemonBitmapSpecies
def pbLoadPokemonBitmapSpecies(pokemon, species, back=false, scale=FRONT_SCALE)
  ret = _shadow_pbLoadPokemonBitmapSpecies(pokemon, species, back, scale)
  if ret
    color = (MultipleForms.call("bitmapColor",pokemon))
    color = Color.new(67,0,255) if pokemon.shadowPokemon? &&  !ret.filename[/_shadow/]
    drawShadowPoke(ret.fullbitmap, color)
    ret.update
  end
  return ret
end

class PokemonIconSprite
  alias _shadow_pokemon= pokemon=
  def pokemon=(value)
    self._shadow_pokemon = value
    if pokemon
      color = (MultipleForms.call("bitmapColor",pokemon))
      color = Color.new(67,0,255) if pokemon.shadowPokemon? &&  !self.filename[/_shadow/]
      drawShadowPoke(self.bitmap, color)
    end
  end
end

# MultipleForms.registerIf(proc{|species| true},{
#  "bitmapColor"=>proc{|pokemon|
#     next
#     next
#  }
# })
