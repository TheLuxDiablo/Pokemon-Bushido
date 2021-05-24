#===============================================================================
# Regular form differences
#===============================================================================

MultipleForms.register(:PIKACHU,{
  "onSetForm" => proc { |pkmn,form,oldForm|
    pkmn.makeFemale if [3..8].include?(form)
    formMoves = [
       :ICICLECRASH,      # Belle Pikachu
       :FLYINGPRESS,      # Libre Pikachu
       :ELECTRICTERRAIN,  # PhD Pikachu
       :DRAININGKISS,     # Pop Star Pikachu
       :METEORMASH        # Rockstar Pikachu
    ]
    idxMoveToReplace = -1
    pkmn.moves.each_with_index do |move,i|
      next if !move
      formMoves.each do |newMove|
        next if !isConst?(move.id,PBMoves,newMove)
        idxMoveToReplace = i
        break
      end
      break if idxMoveToReplace>=0
    end
    if !([3..8].include?(form))
      if idxMoveToReplace>=0
        moveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
        pbMessage(_INTL("{1} forgot {2}...",pkmn.name,moveName))
        pkmn.pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves==0
      end
    else
      newMove = getConst(PBMoves,formMoves[form-4])
      if idxMoveToReplace>=0
        oldMoveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        if newMove && newMove>0
          newMoveName = PBMoves.getName(newMove)
          pkmn.moves[idxMoveToReplace].id = newMove
          pbMessage(_INTL("1,\\wt[16] 2, and\\wt[16]...\\wt[16] ...\\wt[16] ... Ta-da!\\se[Battle ball drop]\1"))
          pbMessage(_INTL("{1} forgot how to use {2}.\\nAnd...\1",pkmn.name,oldMoveName))
          pbMessage(_INTL("\\se[]{1} learned {2}!\\se[Pkmn move learnt]",pkmn.name,newMoveName))
        else
          pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
          pbMessage(_INTL("{1} forgot {2}...",pkmn.name,oldMoveName))
          pkmn.pbLearnMove(:THUNDERWAVE) if pkmn.numMoves==0
        end
      elsif newMove && newMove>0
        pbLearnMove(pkmn,newMove,true)
      end
    end
},
"getForm" => proc { |pkmn|
  next if pkmn.formSimple>=2
  mapPos = pbGetMetadata($game_map.map_id,MetadataMapPosition)
  next 1 if mapPos && mapPos[0]==1   # Tiall region
  next 0
}})

MultipleForms.register(:SLOWBRO,{
  "getSpecificMegaForm" => proc { |pkmn|
    next 2 if (pkmn.form == 0 && pkmn.hasItem?(:SLOWBRONITE))
    next
  },
  "getSpecificUnmegaForm" => proc { |pkmn|
    next 0 if pkmn.form == 2
    next
  }
})


MultipleForms.register(:UNOWN,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(28)
  }
})

MultipleForms.register(:SPINDA,{
  "alterBitmap" => proc { |pkmn,bitmap|
    pbSpindaSpots(pkmn,bitmap)
  }
})

MultipleForms.register(:CASTFORM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:GROUDON,{
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:REDORB)
    next
  }
})

MultipleForms.register(:KYOGRE,{
  "getPrimalForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:BLUEORB)
    next
  }
})


MultipleForms.register(:BURMY,{
  "getFormOnCreation" => proc { |pkmn|
    case pbGetEnvironment
    when PBEnvironment::Rock, PBEnvironment::Sand, PBEnvironment::Cave
      next 1   # Sandy Cloak
    when PBEnvironment::None
      next 2   # Trash Cloak
    else
      next 0   # Plant Cloak
    end
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next if !endBattle || !usedInBattle
    case battle.environment
    when PBEnvironment::Rock, PBEnvironment::Sand, PBEnvironment::Cave
      next 1   # Sandy Cloak
    when PBEnvironment::None
      next 2   # Trash Cloak
    else
      next 0   # Plant Cloak
    end
  }
})

MultipleForms.register(:WORMADAM,{
  "getFormOnCreation" => proc { |pkmn|
    case pbGetEnvironment
    when PBEnvironment::Rock, PBEnvironment::Sand, PBEnvironment::Cave
      next 1   # Sandy Cloak
    when PBEnvironment::None
      next 2   # Trash Cloak
    else
      next 0   # Plant Cloak
    end
  }
})

MultipleForms.register(:CHERRIM,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:ROTOM,{
  "onSetForm" => proc { |pkmn,form,oldForm|
    formMoves = [
       :OVERHEAT,    # Heat, Microwave
       :HYDROPUMP,   # Wash, Washing Machine
       :BLIZZARD,    # Frost, Refrigerator
       :AIRSLASH,    # Fan
       :LEAFSTORM    # Mow, Lawnmower
    ]
    idxMoveToReplace = -1
    pkmn.moves.each_with_index do |move,i|
      next if !move
      formMoves.each do |newMove|
        next if !isConst?(move.id,PBMoves,newMove)
        idxMoveToReplace = i
        break
      end
      break if idxMoveToReplace>=0
    end
    if form==0
      if idxMoveToReplace>=0
        moveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
        pbMessage(_INTL("{1} forgot {2}...",pkmn.name,moveName))
        pkmn.pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves==0
      end
    else
      newMove = getConst(PBMoves,formMoves[form-1])
      if idxMoveToReplace>=0
        oldMoveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        if newMove && newMove>0
          newMoveName = PBMoves.getName(newMove)
          pkmn.moves[idxMoveToReplace].id = newMove
          pbMessage(_INTL("1,\\wt[16] 2, and\\wt[16]...\\wt[16] ...\\wt[16] ... Ta-da!\\se[Battle ball drop]\1"))
          pbMessage(_INTL("{1} forgot how to use {2}.\\nAnd...\1",pkmn.name,oldMoveName))
          pbMessage(_INTL("\\se[]{1} learned {2}!\\se[Pkmn move learnt]",pkmn.name,newMoveName))
        else
          pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
          pbMessage(_INTL("{1} forgot {2}...",pkmn.name,oldMoveName))
          pkmn.pbLearnMove(:THUNDERSHOCK) if pkmn.numMoves==0
        end
      elsif newMove && newMove>0
        pbLearnMove(pkmn,newMove,true)
      end
    end
  }
})

MultipleForms.register(:GIRATINA,{
  "getForm" => proc { |pkmn|
    maps = [49,50,51,72,73]   # Map IDs for Origin Forme
    if pkmn.hasItem?(:GRISEOUSORB) || maps.include?($game_map.map_id)
      next 1
    end
    next 0
  }
})

MultipleForms.register(:SHAYMIN,{
  "getForm" => proc { |pkmn|
    next 0 if pkmn.fainted? || pkmn.status==PBStatuses::FROZEN ||
              PBDayNight.isNight?
  }
})

MultipleForms.register(:ARCEUS,{
  "getForm" => proc { |pkmn|
    next nil if !isConst?(pkmn.ability,PBAbilities,:MULTITYPE)
    typeArray = {
       1  => [:FISTPLATE,:FIGHTINIUMZ],
       2  => [:SKYPLATE,:FLYINIUMZ],
       3  => [:TOXICPLATE,:POISONIUMZ],
       4  => [:EARTHPLATE,:GROUNDIUMZ],
       5  => [:STONEPLATE,:ROCKIUMZ],
       6  => [:INSECTPLATE,:BUGINIUMZ],
       7  => [:SPOOKYPLATE,:GHOSTIUMZ],
       8  => [:IRONPLATE,:STEELIUMZ],
       10 => [:FLAMEPLATE,:FIRIUMZ],
       11 => [:SPLASHPLATE,:WATERIUMZ],
       12 => [:MEADOWPLATE,:GRASSIUMZ],
       13 => [:ZAPPLATE,:ELECTRIUMZ],
       14 => [:MINDPLATE,:PSYCHIUMZ],
       15 => [:ICICLEPLATE,:ICIUMZ],
       16 => [:DRACOPLATE,:DRAGONIUMZ],
       17 => [:DREADPLATE,:DARKINIUMZ],
       18 => [:PIXIEPLATE,:FAIRIUMZ]
    }
    ret = 0
    next 0 if !pkmn.hasItem?
    typeArray.each do |f, items|
      for item in items
        next if !pkmn.hasItem?(item)
        ret = f
        break
      end
      break if ret>0
    end
    next ret
  }
})

MultipleForms.register(:BASCULIN,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(2)
  }
})

MultipleForms.register(:DARMANITAN,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.form==2
    next 1 if pkmn.form==3
  }
})

MultipleForms.register(:DEERLING,{
  "getForm" => proc { |pkmn|
    next pbGetSeason
  }
})

MultipleForms.copy(:DEERLING,:SAWSBUCK)

MultipleForms.register(:KYUREM,{
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next pkmn.form+2 if pkmn.form==1 || pkmn.form==2
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form-2 if pkmn.form>=3   # Fused forms stop glowing
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    case form
    when 0   # Normal
      pkmn.moves.each do |move|
        next if !move
        if (isConst?(move.id,PBMoves,:ICEBURN) ||
           isConst?(move.id,PBMoves,:FREEZESHOCK)) && hasConst?(PBMoves,:GLACIATE)
          move.id = getConst(PBMoves,:GLACIATE)
        end
        if (isConst?(move.id,PBMoves,:FUSIONFLARE) ||
           isConst?(move.id,PBMoves,:FUSIONBOLT)) && hasConst?(PBMoves,:SCARYFACE)
          move.id = getConst(PBMoves,:SCARYFACE)
        end
      end
    when 1   # White
      pkmn.moves.each do |move|
        next if !move
        if isConst?(move.id,PBMoves,:GLACIATE) && hasConst?(PBMoves,:ICEBURN)
          move.id = getConst(PBMoves,:ICEBURN)
        end
        if isConst?(move.id,PBMoves,:SCARYFACE) && hasConst?(PBMoves,:FUSIONFLARE)
          move.id = getConst(PBMoves,:FUSIONFLARE)
        end
      end
    when 2   # Black
      pkmn.moves.each do |move|
        next if !move
        if isConst?(move.id,PBMoves,:GLACIATE) && hasConst?(PBMoves,:FREEZESHOCK)
          move.id = getConst(PBMoves,:FREEZESHOCK)
        end
        if isConst?(move.id,PBMoves,:SCARYFACE) && hasConst?(PBMoves,:FUSIONBOLT)
          move.id = getConst(PBMoves,:FUSIONBOLT)
        end
      end
    end
  }
})

MultipleForms.register(:KELDEO,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasMove?(:SECRETSWORD) # Resolute Form
    next 0                                # Ordinary Form
  }
})

MultipleForms.register(:MELOETTA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:GENESECT,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.hasItem?(:SHOCKDRIVE)
    next 2 if pkmn.hasItem?(:BURNDRIVE)
    next 3 if pkmn.hasItem?(:CHILLDRIVE)
    next 4 if pkmn.hasItem?(:DOUSEDRIVE)
    next 0
  }
})

MultipleForms.register(:GRENINJA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 1 if pkmn.form == 2 && (pkmn.fainted? || endBattle)
  }
})

MultipleForms.register(:SCATTERBUG,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(18)
  }
})

MultipleForms.copy(:SCATTERBUG,:SPEWPA,:VIVILLON)

MultipleForms.register(:FLABEBE,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(6)
  }
})

MultipleForms.copy(:FLABEBE,:FLOETTE,:FLORGES)

MultipleForms.register(:FURFROU,{
  "getForm" => proc { |pkmn|
    if !pkmn.formTime || pbGetTimeNow.to_i>pkmn.formTime.to_i+60*60*24*5   # 5 days
      next 0
    end
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    pkmn.formTime = (form>0) ? pbGetTimeNow.to_i : nil
  }
})

MultipleForms.register(:ESPURR,{
  "getForm" => proc { |pkmn|
    next pkmn.gender
  }
})

MultipleForms.copy(:ESPURR,:MEOWSTIC)

MultipleForms.register(:AEGISLASH,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:PUMPKABOO,{
  "getFormOnCreation" => proc { |pkmn|
    r = rand(100)
    if r<5;     next 3   # Super Size (5%)
    elsif r<20; next 2   # Large (15%)
    elsif r<65; next 1   # Average (45%)
    end
    next 0               # Small (35%)
  }
})

MultipleForms.copy(:PUMPKABOO,:GOURGEIST)

MultipleForms.register(:XERNEAS,{
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next 1
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:ZYGARDE,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form-2 if pkmn.form>=2 && (pkmn.fainted? || endBattle)
  }
})

MultipleForms.register(:HOOPA,{
  "getForm" => proc { |pkmn|
    if !pkmn.formTime || pbGetTimeNow.to_i>pkmn.formTime.to_i+60*60*24*3   # 3 days
      next 0
    end
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    pkmn.formTime = (form>0) ? pbGetTimeNow.to_i : nil
  }
})

MultipleForms.register(:ORICORIO,{
  "getFormOnCreation" => proc { |pkmn|
    next rand(4)   # 0=red, 1=yellow, 2=pink, 3=purple
  },
})

MultipleForms.register(:ROCKRUFF,{
  "getForm" => proc { |pkmn|
    next if pkmn.formSimple>=2   # Own Tempo Rockruff cannot become another form
    next 1 if PBDayNight.isNight?
    next 0
  }
})

MultipleForms.register(:LYCANROC,{
  "getFormOnCreation" => proc { |pkmn|
    next 2 if PBDayNight.isEvening?   # Dusk
    next 1 if PBDayNight.isNight?     # Midnight
    next 0                            # Midday
  },
})

MultipleForms.register(:WISHIWASHI,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:SILVALLY,{
  "getForm" => proc { |pkmn|
    next nil if !isConst?(pkmn.ability,PBAbilities,:RKSSYSTEM)
    typeArray = {
       1  => [:FIGHTINGMEMORY],
       2  => [:FLYINGMEMORY],
       3  => [:POISONMEMORY],
       4  => [:GROUNDMEMORY],
       5  => [:ROCKMEMORY],
       6  => [:BUGMEMORY],
       7  => [:GHOSTMEMORY],
       8  => [:STEELMEMORY],
       10 => [:FIREMEMORY],
       11 => [:WATERMEMORY],
       12 => [:GRASSMEMORY],
       13 => [:ELECTRICMEMORY],
       14 => [:PSYCHICMEMORY],
       15 => [:ICEMEMORY],
       16 => [:DRAGONMEMORY],
       17 => [:DARKMEMORY],
       18 => [:FAIRYMEMORY]
    }
    ret = 0
    typeArray.each do |f, items|
      for item in items
        next if !pkmn.hasItem?(item)
        ret = f
        break
      end
      break if ret>0
    end
    next ret
  }
})

MultipleForms.register(:MINIOR,{
  "getFormOnCreation" => proc { |pkmn|
    next 7+rand(7)   # Meteor forms are 0-6, Core forms are 7-13
  },
  "getFormOnEnteringBattle" => proc { |pkmn,wild|
    next pkmn.form-7 if pkmn.form>=7 && wild   # Wild Minior always appear in Meteor form
  },
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next pkmn.form+7 if pkmn.form<7
  }
})

MultipleForms.register(:MIMIKYU,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:NECROZMA,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    # Fused forms are 1 and 2, Ultra form is 3 or 4 depending on which fusion
    next pkmn.form-2 if pkmn.form>=3 && (pkmn.fainted? || endBattle)
  },
  "onSetForm" => proc { |pkmn,form,oldForm|
    next if form>2 || oldForm>2   # Ultra form changes don't affect moveset
    formMoves = [
       :SUNSTEELSTRIKE,   # Dusk Mane (with Solgaleo) (form 1)
       :MOONGEISTBEAM     # Dawn Wings (with Lunala) (form 2)
    ]
    if form==0
      idxMoveToReplace = -1
      pkmn.moves.each_with_index do |move,i|
        next if !move
        formMoves.each do |newMove|
          next if !isConst?(move.id,PBMoves,newMove)
          idxMoveToReplace = i
          break
        end
        break if idxMoveToReplace>=0
      end
      if idxMoveToReplace>=0
        moveName = PBMoves.getName(pkmn.moves[idxMoveToReplace].id)
        pkmn.pbDeleteMoveAtIndex(idxMoveToReplace)
        pbMessage(_INTL("{1} forgot {2}...",pkmn.name,moveName))
        pkmn.pbLearnMove(:CONFUSION) if pkmn.numMoves==0
      end
    else
      newMove = getConst(PBMoves,formMoves[form-1])
      if newMove && newMove>0
        pbLearnMove(pkmn,newMove,true)
      end
    end
  }
})

MultipleForms.register(:TOXEL,{
  "getFormOnCreation" => proc { |pkmn|
   natures=[1,5,7,10,12,15,16,17,18,20,21,23]
   lowkey=false
   nature=pkmn.nature
   lowkey = true if natures.include?(nature)
   next 1 if lowkey
   next 0
  },
})

MultipleForms.copy(:TOXEL,:TOXTRICITY)

MultipleForms.register(:EISCUE,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:INDEEDEE,{
  "getForm" => proc { |pkmn|
    next pkmn.gender
  }
})

MultipleForms.register(:ZAMAZENTA,{
  "getForm" => proc { |pkmn|
    next 1 if isConst?(pkmn.item,PBItems,:RUSTEDSHIELD)
    next 0
  }
})

MultipleForms.register(:ZACIAN,{
  "getForm" => proc { |pkmn|
    next 1 if isConst?(pkmn.item,PBItems,:RUSTEDSWORD)
    next 0
  }
})

MultipleForms.register(:MORPEKO,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0 if pkmn.fainted? || endBattle
  }
})

MultipleForms.register(:CRAMORANT,{
  "getFormOnLeavingBattle" => proc { |pkmn,battle,usedInBattle,endBattle|
    next 0
  }
})

MultipleForms.register(:CALYREX,{
  "onSetForm" => proc { |pkmn,form,oldForm|
    case form
    when 0   # Normal
      exclusiveMoves = [:TACKLE, :TAILWHIP, :DOUBLEKICK, :AVALANCHE, :HEX, :STOMP, :TORMENT, :CONFUSERAY,
         :MIST, :HAZE, :ICICLECRASH, :SHADOWBALL, :TAKEDOWN, :IRONDEFENSE, :AGILITY, :THRASH, :TAUNT, :DISABLE,
          :DOUBLEEDGE, :SWORDSDANCE, :NASTYPLOT, :GLACIALLANCE, :ASTRALBARRAGE].map! { |name| getID(PBMoves, name) }
      pkmn.moves.each_with_index do |move,i|
        next if !move || move.id==0
        if exclusiveMoves.include?(move.id)
          pbMessage(_INTL("{1} forgot {2}...",pkmn.name,PBMoves.getName(move.id)))
          pkmn.pbDeleteMoveAtIndex(i)
        end
      end
      pkmn.pbLearnMove(:CONFUSION) if pkmn.numMoves==0
    when 1   # Ice Rider
      pbLearnMove(pkmn,getID(PBMoves,:GLACIALLANCE),true) if hasConst?(PBMoves,:GLACIALLANCE)
    when 2   # Black
      pbLearnMove(pkmn,getID(PBMoves,:ASTRALBARRAGE),true) if hasConst?(PBMoves,:ASTRALBARRAGE)
    end
  }
})

#===============================================================================
# Alolan forms
#===============================================================================

# These species don't have visually different Alolan forms, but they need to
# evolve into different forms depending on the location where they evolved.
MultipleForms.register(:EXEGGCUTE,{
  "getForm" => proc { |pkmn|
    next if pkmn.formSimple>=2
    mapPos = pbGetMetadata($game_map.map_id,MetadataMapPosition)
    next 1 if mapPos && mapPos[0]==1   # Tiall region
    next 0
  }
})

MultipleForms.copy(:EXEGGCUTE,:CUBONE)

#===============================================================================
# Galarian forms
#===============================================================================

# These species don't have visually different Galarian forms, but they need to
# evolve into different forms depending on the location where they evolved.
MultipleForms.register(:KOFFING,{
  "getForm" => proc { |pkmn|
    next if pkmn.formSimple>=2
    mapPos = pbGetMetadata($game_map.map_id,MetadataMapPosition)
    next 1 if mapPos && mapPos[0]==1   # Tiall region
    next 0
  }
})

MultipleForms.copy(:KOFFING,:MIMEJR)

MultipleForms.register(:SLOWPOKE,{
"getFormOnCreation"=>proc{|pokemon|
   maps=[1]
   if $game_map && maps.include?($game_map.map_id)
     next 0
   else
     next 1
   end
}
})
MultipleForms.copy(:SLOWPOKE,:SLOWBRO,:SLOWKING,
                   :FARFETCHD,
                   :SANDSHREW,:SANDSLASH,
                   :ZIGZAGOON,:LINOONE,
                   :MRMIME
                 )
