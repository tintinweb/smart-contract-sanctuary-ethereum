// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import './TRColors.sol';

interface ITRRolls {

  struct RelicInfo {
    string element;
    string palette;
    string essence;
    uint256 colorCount;
    string style;
    string speed;
    string gravity;
    string display;
    string relicType;
    string glyphType;
    uint256 runeflux;
    uint256 corruption;
    uint256 grailId;
    uint256[] grailGlyph;
  }

  function getRelicInfo(TRKeys.RuneCore memory core) external view returns (RelicInfo memory);
  function getElement(TRKeys.RuneCore memory core) external view returns (string memory);
  function getPalette(TRKeys.RuneCore memory core) external view returns (string memory);
  function getEssence(TRKeys.RuneCore memory core) external view returns (string memory);
  function getStyle(TRKeys.RuneCore memory core) external view returns (string memory);
  function getSpeed(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGravity(TRKeys.RuneCore memory core) external view returns (string memory);
  function getDisplay(TRKeys.RuneCore memory core) external view returns (string memory);
  function getColorCount(TRKeys.RuneCore memory core) external view returns (uint256);
  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index) external view returns (string memory);
  function getRelicType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGlyphType(TRKeys.RuneCore memory core) external view returns (string memory);
  function getRuneflux(TRKeys.RuneCore memory core) external view returns (uint256);
  function getCorruption(TRKeys.RuneCore memory core) external view returns (uint256);
  function getDescription(TRKeys.RuneCore memory core) external view returns (string memory);
  function getGrailId(TRKeys.RuneCore memory core) external pure returns (uint256);

}

/// @notice The Reliquary Rarity Distribution
contract TRRolls is Ownable, ITRRolls {

  mapping(uint256 => address) public grailContracts;

  error GrailsAreImmutable();

  constructor() Ownable() {}

  function getRelicInfo(TRKeys.RuneCore memory core)
    override
    public
    view
    returns (RelicInfo memory)
  {
    RelicInfo memory info;
    info.element = getElement(core);
    info.palette = getPalette(core);
    info.essence = getEssence(core);
    info.colorCount = getColorCount(core);
    info.style = getStyle(core);
    info.speed = getSpeed(core);
    info.gravity = getGravity(core);
    info.display = getDisplay(core);
    info.relicType = getRelicType(core);
    info.glyphType = getGlyphType(core);
    info.runeflux = getRuneflux(core);
    info.corruption = getCorruption(core);
    info.grailId = getGrailId(core);

    if (info.grailId != TRKeys.GRAIL_ID_NONE) {
      info.grailGlyph = Grail(grailContracts[info.grailId]).getGlyph();
    }

    return info;
  }

  function getElement(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getElement();
    }

    if (bytes(core.transmutation).length > 0) {
      return core.transmutation;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_ELEMENT);
    if (roll <= uint256(125)) {
      return TRKeys.ELEM_NATURE;
    } else if (roll <= uint256(250)) {
      return TRKeys.ELEM_LIGHT;
    } else if (roll <= uint256(375)) {
      return TRKeys.ELEM_WATER;
    } else if (roll <= uint256(500)) {
      return TRKeys.ELEM_EARTH;
    } else if (roll <= uint256(625)) {
      return TRKeys.ELEM_WIND;
    } else if (roll <= uint256(750)) {
      return TRKeys.ELEM_ARCANE;
    } else if (roll <= uint256(875)) {
      return TRKeys.ELEM_SHADOW;
    } else {
      return TRKeys.ELEM_FIRE;
    }
  }

  function getPalette(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getPalette();
    }

    if (core.colors.length > 0) {
      return TRKeys.ANY_PAL_CUSTOM;
    }

    string memory element = getElement(core);
    uint256 roll = roll1000(core, TRKeys.ROLL_PALETTE);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNaturePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindPalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcanePalette(roll);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowPalette(roll);
    } else {
      return getFirePalette(roll);
    }
  }

  function getNaturePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.NAT_PAL_JUNGLE;
    } else if (roll <= 900) {
      return TRKeys.NAT_PAL_CAMOUFLAGE;
    } else {
      return TRKeys.NAT_PAL_BIOLUMINESCENCE;
    }
  }

  function getLightPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.LIG_PAL_PASTEL;
    } else if (roll <= 900) {
      return TRKeys.LIG_PAL_INFRARED;
    } else {
      return TRKeys.LIG_PAL_ULTRAVIOLET;
    }
  }

  function getWaterPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WAT_PAL_FROZEN;
    } else if (roll <= 900) {
      return TRKeys.WAT_PAL_DAWN;
    } else {
      return TRKeys.WAT_PAL_OPALESCENT;
    }
  }

  function getEarthPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.EAR_PAL_COAL;
    } else if (roll <= 900) {
      return TRKeys.EAR_PAL_SILVER;
    } else {
      return TRKeys.EAR_PAL_GOLD;
    }
  }

  function getWindPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.WIN_PAL_BERRY;
    } else if (roll <= 900) {
      return TRKeys.WIN_PAL_THUNDER;
    } else {
      return TRKeys.WIN_PAL_AERO;
    }
  }

  function getArcanePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.ARC_PAL_FROSTFIRE;
    } else if (roll <= 900) {
      return TRKeys.ARC_PAL_COSMIC;
    } else {
      return TRKeys.ARC_PAL_COLORLESS;
    }
  }

  function getShadowPalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.SHA_PAL_DARKNESS;
    } else if (roll <= 900) {
      return TRKeys.SHA_PAL_VOID;
    } else {
      return TRKeys.SHA_PAL_UNDEAD;
    }
  }

  function getFirePalette(uint256 roll) public pure returns (string memory) {
    if (roll <= 600) {
      return TRKeys.FIR_PAL_HEAT;
    } else if (roll <= 900) {
      return TRKeys.FIR_PAL_EMBER;
    } else {
      return TRKeys.FIR_PAL_CORRUPTED;
    }
  }

  function getEssence(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getEssence();
    }

    string memory element = getElement(core);
    string memory relicType = getRelicType(core);
    if (TRUtils.compare(element, TRKeys.ELEM_NATURE)) {
      return getNatureEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_LIGHT)) {
      return getLightEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WATER)) {
      return getWaterEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_EARTH)) {
      return getEarthEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_WIND)) {
      return getWindEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_ARCANE)) {
      return getArcaneEssence(relicType);
    } else if (TRUtils.compare(element, TRKeys.ELEM_SHADOW)) {
      return getShadowEssence(relicType);
    } else {
      return getFireEssence(relicType);
    }
  }

  function getNatureEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.NAT_ESS_FOREST;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.NAT_ESS_SWAMP;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.NAT_ESS_WILDBLOOD;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.NAT_ESS_LIFE;
    } else {
      return TRKeys.NAT_ESS_SOUL;
    }
  }

  function getLightEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.LIG_ESS_HEAVENLY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.LIG_ESS_FAE;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.LIG_ESS_PRISMATIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.LIG_ESS_RADIANT;
    } else {
      return TRKeys.LIG_ESS_PHOTONIC;
    }
  }

  function getWaterEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WAT_ESS_TIDAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WAT_ESS_ARCTIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WAT_ESS_STORM;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WAT_ESS_ILLUVIAL;
    } else {
      return TRKeys.WAT_ESS_UNDINE;
    }
  }

  function getEarthEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.EAR_ESS_MINERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.EAR_ESS_CRAGGY;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.EAR_ESS_DWARVEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.EAR_ESS_GNOMIC;
    } else {
      return TRKeys.EAR_ESS_CRYSTAL;
    }
  }

  function getWindEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.WIN_ESS_SYLPHIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.WIN_ESS_VISCERAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.WIN_ESS_FROSTED;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.WIN_ESS_ELECTRIC;
    } else {
      return TRKeys.WIN_ESS_MAGNETIC;
    }
  }

  function getArcaneEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.ARC_ESS_MAGIC;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.ARC_ESS_ASTRAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.ARC_ESS_FORBIDDEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.ARC_ESS_RUNIC;
    } else {
      return TRKeys.ARC_ESS_UNKNOWN;
    }
  }

  function getShadowEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.SHA_ESS_NIGHT;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.SHA_ESS_FORGOTTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.SHA_ESS_ABYSSAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.SHA_ESS_EVIL;
    } else {
      return TRKeys.SHA_ESS_LOST;
    }
  }

  function getFireEssence(string memory relicType) public pure returns (string memory) {
    if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TRINKET)) {
      return TRKeys.FIR_ESS_INFERNAL;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_TALISMAN)) {
      return TRKeys.FIR_ESS_MOLTEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_AMULET)) {
      return TRKeys.FIR_ESS_ASHEN;
    } else if (TRUtils.compare(relicType, TRKeys.RELIC_TYPE_FOCUS)) {
      return TRKeys.FIR_ESS_DRACONIC;
    } else {
      return TRKeys.FIR_ESS_CELESTIAL;
    }
  }

  function getStyle(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getStyle();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_STYLE);
    if (roll <= 760) {
      return TRKeys.STYLE_SMOOTH;
    } else if (roll <= 940) {
      return TRKeys.STYLE_SILK;
    } else if (roll <= 980) {
      return TRKeys.STYLE_PAJAMAS;
    } else {
      return TRKeys.STYLE_SKETCH;
    }
  }

  function getSpeed(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getSpeed();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_SPEED);
    if (roll <= 70) {
      return TRKeys.SPEED_ZEN;
    } else if (roll <= 260) {
      return TRKeys.SPEED_TRANQUIL;
    } else if (roll <= 760) {
      return TRKeys.SPEED_NORMAL;
    } else if (roll <= 890) {
      return TRKeys.SPEED_FAST;
    } else if (roll <= 960) {
      return TRKeys.SPEED_SWIFT;
    } else {
      return TRKeys.SPEED_HYPER;
    }
  }

  function getGravity(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getGravity();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_GRAVITY);
    if (roll <= 50) {
      return TRKeys.GRAV_LUNAR;
    } else if (roll <= 150) {
      return TRKeys.GRAV_ATMOSPHERIC;
    } else if (roll <= 340) {
      return TRKeys.GRAV_LOW;
    } else if (roll <= 730) {
      return TRKeys.GRAV_NORMAL;
    } else if (roll <= 920) {
      return TRKeys.GRAV_HIGH;
    } else if (roll <= 970) {
      return TRKeys.GRAV_MASSIVE;
    } else if (roll <= 995) {
      return TRKeys.GRAV_STELLAR;
    } else {
      return TRKeys.GRAV_GALACTIC;
    }
  }

  function getDisplay(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDisplay();
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_DISPLAY);
    if (roll <= 250) {
      return TRKeys.DISPLAY_NORMAL;
    } else if (roll <= 500) {
      return TRKeys.DISPLAY_MIRRORED;
    } else if (roll <= 750) {
      return TRKeys.DISPLAY_UPSIDEDOWN;
    } else {
      return TRKeys.DISPLAY_MIRROREDUPSIDEDOWN;
    }
  }

  function getColorCount(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getColorCount();
    }

    string memory style = getStyle(core);
    if (TRUtils.compare(style, TRKeys.STYLE_SILK)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_PAJAMAS)) {
      return 5;
    } else if (TRUtils.compare(style, TRKeys.STYLE_SKETCH)) {
      return 4;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_COLORCOUNT);
    if (roll <= 400) {
      return 2;
    } else if (roll <= 750) {
      return 3;
    } else {
      return 4;
    }
  }

  function getColorByIndex(TRKeys.RuneCore memory core, uint256 index)
    override
    public
    view
    returns (string memory)
  {
    // if the requested index exceeds the color count, return empty string
    if (index >= getColorCount(core)) {
      return '';
    }

    // if we've imagined new colors, use them instead
    if (core.colors.length > index) {
      return TRUtils.getColorCode(core.colors[index]);
    }

    // fetch the color palette
    uint256[] memory colorInts;
    uint256 colorIntCount;
    (colorInts, colorIntCount) = TRColors.get(getPalette(core));

    // shuffle the color palette
    uint256 i;
    uint256 temp;
    uint256 count = colorIntCount;
    while (count > 0) {
      string memory rollKey = string(abi.encodePacked(
        TRKeys.ROLL_SHUFFLE,
        TRUtils.toString(count)
      ));

      i = roll1000(core, rollKey) % count;

      temp = colorInts[--count];
      colorInts[count] = colorInts[i];
      colorInts[i] = temp;
    }

    // slightly adjust the RGB channels of the color to make it unique
    temp = getWobbledColor(core, index, colorInts[index % colorIntCount]);

    // return a hex code (without the #)
    return TRUtils.getColorCode(temp);
  }

  function getWobbledColor(TRKeys.RuneCore memory core, uint256 index, uint256 color)
    public
    pure
    returns (uint256)
  {
    uint256 r = (color >> uint256(16)) & uint256(255);
    uint256 g = (color >> uint256(8)) & uint256(255);
    uint256 b = color & uint256(255);

    string memory k = TRUtils.toString(index);
    uint256 dr = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RED, k))) % 8;
    uint256 dg = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREEN, k))) % 8;
    uint256 db = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUE, k))) % 8;
    uint256 rSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_REDSIGN, k))) % 2;
    uint256 gSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_GREENSIGN, k))) % 2;
    uint256 bSign = rollMax(core, string(abi.encodePacked(TRKeys.ROLL_BLUESIGN, k))) % 2;

    if (rSign == 0) {
      if (r > dr) {
        r -= dr;
      } else {
        r = 0;
      }
    } else {
      if (r + dr <= 255) {
        r += dr;
      } else {
        r = 255;
      }
    }

    if (gSign == 0) {
      if (g > dg) {
        g -= dg;
      } else {
        g = 0;
      }
    } else {
      if (g + dg <= 255) {
        g += dg;
      } else {
        g = 255;
      }
    }

    if (bSign == 0) {
      if (b > db) {
        b -= db;
      } else {
        b = 0;
      }
    } else {
      if (b + db <= 255) {
        b += db;
      } else {
        b = 255;
      }
    }

    return uint256((r << uint256(16)) | (g << uint256(8)) | b);
  }

  function getRelicType(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRelicType();
    }

    if (core.isDivinityQuestLoot) {
      return TRKeys.RELIC_TYPE_CURIO;
    }

    uint256 roll = roll1000(core, TRKeys.ROLL_RELICTYPE);
    if (roll <= 360) {
      return TRKeys.RELIC_TYPE_TRINKET;
    } else if (roll <= 620) {
      return TRKeys.RELIC_TYPE_TALISMAN;
    } else if (roll <= 820) {
      return TRKeys.RELIC_TYPE_AMULET;
    } else if (roll <= 960) {
      return TRKeys.RELIC_TYPE_FOCUS;
    } else {
      return TRKeys.RELIC_TYPE_CURIO;
    }
  }

  function getGlyphType(TRKeys.RuneCore memory core) override public pure returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return TRKeys.GLYPH_TYPE_GRAIL;
    }

    if (core.glyph.length > 0) {
      return TRKeys.GLYPH_TYPE_CUSTOM;
    }

    return TRKeys.GLYPH_TYPE_NONE;
  }

  function getRuneflux(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getRuneflux();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_RUNEFLUX) % 300;
    }

    return roll1000(core, TRKeys.ROLL_RUNEFLUX) - 1;
  }

  function getCorruption(TRKeys.RuneCore memory core) override public view returns (uint256) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getCorruption();
    }

    if (core.isDivinityQuestLoot) {
      return 700 + rollMax(core, TRKeys.ROLL_CORRUPTION) % 300;
    }

    return roll1000(core, TRKeys.ROLL_CORRUPTION) - 1;
  }

  function getDescription(TRKeys.RuneCore memory core) override public view returns (string memory) {
    uint256 grailId = getGrailId(core);
    if (grailId != TRKeys.GRAIL_ID_NONE) {
      return Grail(grailContracts[grailId]).getDescription();
    }

    return '';
  }

  function getGrailId(TRKeys.RuneCore memory core) override public pure returns (uint256) {
    uint256 grailId = TRKeys.GRAIL_ID_NONE;

    if (bytes(core.hiddenLeyLines).length > 0) {
      uint256 rollDist = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_GRAILS);
      uint256 digits = 1 + rollDist % TRKeys.GRAIL_DISTRIBUTION;
      for (uint256 i; i < TRKeys.GRAIL_COUNT; i++) {
        if (core.tokenId == digits + TRKeys.GRAIL_DISTRIBUTION * i) {
          uint256 rollShuf = TRUtils.random(core.hiddenLeyLines) ^ TRUtils.random(TRKeys.ROLL_ELEMENT);
          uint256 offset = rollShuf % TRKeys.GRAIL_COUNT;
          grailId = 1 + (i + offset) % TRKeys.GRAIL_COUNT;
          break;
        }
      }
    }

    return grailId;
  }

  function rollMax(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    string memory tokenKey = string(abi.encodePacked(key, TRUtils.toString(7 * core.tokenId)));
    return TRUtils.random(core.runeHash) ^ TRUtils.random(tokenKey);
  }

  function roll1000(TRKeys.RuneCore memory core, string memory key) internal pure returns (uint256) {
    return 1 + rollMax(core, key) % 1000;
  }

  function rollColor(TRKeys.RuneCore memory core, uint256 index) internal pure returns (uint256) {
    string memory k = TRUtils.toString(index);
    return rollMax(core, string(abi.encodePacked(TRKeys.ROLL_RANDOMCOLOR, k))) % 16777216;
  }

  function setGrailContract(uint256 grailId, address grailContract) public onlyOwner {
    if (grailContracts[grailId] != address(0)) revert GrailsAreImmutable();

    grailContracts[grailId] = grailContract;
  }

}



abstract contract Grail {
  function getElement() external pure virtual returns (string memory);
  function getPalette() external pure virtual returns (string memory);
  function getEssence() external pure virtual returns (string memory);
  function getStyle() external pure virtual returns (string memory);
  function getSpeed() external pure virtual returns (string memory);
  function getGravity() external pure virtual returns (string memory);
  function getDisplay() external pure virtual returns (string memory);
  function getColorCount() external pure virtual returns (uint256);
  function getRelicType() external pure virtual returns (string memory);
  function getRuneflux() external pure virtual returns (uint256);
  function getCorruption() external pure virtual returns (uint256);
  function getGlyph() external pure virtual returns (uint256[] memory);
  function getDescription() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './TRKeys.sol';

/// @notice The Reliquary Color Palettes
library TRColors {

  function get(string memory palette)
    public
    pure
    returns (uint256[] memory, uint256)
  {
    uint256[] memory colorInts = new uint256[](12);
    uint256 colorIntCount = 0;

    if (TRUtils.compare(palette, TRKeys.NAT_PAL_JUNGLE)) {
      colorInts[0] = uint256(3299866);
      colorInts[1] = uint256(1256965);
      colorInts[2] = uint256(2375731);
      colorInts[3] = uint256(67585);
      colorInts[4] = uint256(16749568);
      colorInts[5] = uint256(16776295);
      colorInts[6] = uint256(16748230);
      colorInts[7] = uint256(16749568);
      colorInts[8] = uint256(67585);
      colorInts[9] = uint256(2375731);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_CAMOUFLAGE)) {
      colorInts[0] = uint256(10328673);
      colorInts[1] = uint256(6245168);
      colorInts[2] = uint256(2171169);
      colorInts[3] = uint256(4610624);
      colorInts[4] = uint256(5269320);
      colorInts[5] = uint256(4994846);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.NAT_PAL_BIOLUMINESCENCE)) {
      colorInts[0] = uint256(2434341);
      colorInts[1] = uint256(4194315);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(7270568);
      colorInts[4] = uint256(9117400);
      colorInts[5] = uint256(1599944);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_PASTEL)) {
      colorInts[0] = uint256(16761760);
      colorInts[1] = uint256(16756669);
      colorInts[2] = uint256(16636817);
      colorInts[3] = uint256(13762047);
      colorInts[4] = uint256(8714928);
      colorInts[5] = uint256(9425908);
      colorInts[6] = uint256(16499435);
      colorInts[7] = uint256(10587345);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_INFRARED)) {
      colorInts[0] = uint256(16642938);
      colorInts[1] = uint256(16755712);
      colorInts[2] = uint256(15883521);
      colorInts[3] = uint256(13503623);
      colorInts[4] = uint256(8257951);
      colorInts[5] = uint256(327783);
      colorInts[6] = uint256(13503623);
      colorInts[7] = uint256(15883521);
      colorIntCount = uint256(8);
    } else if (TRUtils.compare(palette, TRKeys.LIG_PAL_ULTRAVIOLET)) {
      colorInts[0] = uint256(14200063);
      colorInts[1] = uint256(5046460);
      colorInts[2] = uint256(16775167);
      colorInts[3] = uint256(16024318);
      colorInts[4] = uint256(11665662);
      colorInts[5] = uint256(1507410);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_FROZEN)) {
      colorInts[0] = uint256(13034750);
      colorInts[1] = uint256(4102128);
      colorInts[2] = uint256(826589);
      colorInts[3] = uint256(346764);
      colorInts[4] = uint256(6707);
      colorInts[5] = uint256(1277652);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_DAWN)) {
      colorInts[0] = uint256(334699);
      colorInts[1] = uint256(610965);
      colorInts[2] = uint256(5408708);
      colorInts[3] = uint256(16755539);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.WAT_PAL_OPALESCENT)) {
      colorInts[0] = uint256(15985337);
      colorInts[1] = uint256(15981758);
      colorInts[2] = uint256(15713994);
      colorInts[3] = uint256(13941977);
      colorInts[4] = uint256(8242919);
      colorInts[5] = uint256(15985337);
      colorInts[6] = uint256(15981758);
      colorInts[7] = uint256(15713994);
      colorInts[8] = uint256(13941977);
      colorInts[9] = uint256(8242919);
      colorIntCount = uint256(10);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_COAL)) {
      colorInts[0] = uint256(3613475);
      colorInts[1] = uint256(1577233);
      colorInts[2] = uint256(4407359);
      colorInts[3] = uint256(2894892);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_SILVER)) {
      colorInts[0] = uint256(16053492);
      colorInts[1] = uint256(15329769);
      colorInts[2] = uint256(10132122);
      colorInts[3] = uint256(6776679);
      colorInts[4] = uint256(3881787);
      colorInts[5] = uint256(1579032);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.EAR_PAL_GOLD)) {
      colorInts[0] = uint256(16373583);
      colorInts[1] = uint256(12152866);
      colorInts[2] = uint256(12806164);
      colorInts[3] = uint256(4725765);
      colorInts[4] = uint256(2557441);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_BERRY)) {
      colorInts[0] = uint256(5428970);
      colorInts[1] = uint256(13323211);
      colorInts[2] = uint256(15385745);
      colorInts[3] = uint256(13355851);
      colorInts[4] = uint256(15356630);
      colorInts[5] = uint256(14903600);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_THUNDER)) {
      colorInts[0] = uint256(924722);
      colorInts[1] = uint256(9464002);
      colorInts[2] = uint256(470093);
      colorInts[3] = uint256(6378394);
      colorInts[4] = uint256(16246484);
      colorInts[5] = uint256(12114921);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.WIN_PAL_AERO)) {
      colorInts[0] = uint256(4609);
      colorInts[1] = uint256(803087);
      colorInts[2] = uint256(2062109);
      colorInts[3] = uint256(11009906);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_FROSTFIRE)) {
      colorInts[0] = uint256(16772570);
      colorInts[1] = uint256(4043519);
      colorInts[2] = uint256(16758832);
      colorInts[3] = uint256(16720962);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COSMIC)) {
      colorInts[0] = uint256(1182264);
      colorInts[1] = uint256(10834562);
      colorInts[2] = uint256(4269159);
      colorInts[3] = uint256(16769495);
      colorInts[4] = uint256(3351916);
      colorInts[5] = uint256(12612224);
      colorIntCount = uint256(6);
    } else if (TRUtils.compare(palette, TRKeys.ARC_PAL_COLORLESS)) {
      colorInts[0] = uint256(1644825);
      colorInts[1] = uint256(15132390);
      colorIntCount = uint256(2);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_DARKNESS)) {
      colorInts[0] = uint256(2885188);
      colorInts[1] = uint256(1572943);
      colorInts[2] = uint256(1179979);
      colorInts[3] = uint256(657930);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_VOID)) {
      colorInts[0] = uint256(1572943);
      colorInts[1] = uint256(4194415);
      colorInts[2] = uint256(6488209);
      colorInts[3] = uint256(13051525);
      colorInts[4] = uint256(657930);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.SHA_PAL_UNDEAD)) {
      colorInts[0] = uint256(3546937);
      colorInts[1] = uint256(50595);
      colorInts[2] = uint256(7511983);
      colorInts[3] = uint256(7563923);
      colorInts[4] = uint256(10535352);
      colorIntCount = uint256(5);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_HEAT)) {
      colorInts[0] = uint256(590337);
      colorInts[1] = uint256(12141574);
      colorInts[2] = uint256(15908162);
      colorInts[3] = uint256(6886400);
      colorIntCount = uint256(4);
    } else if (TRUtils.compare(palette, TRKeys.FIR_PAL_EMBER)) {
      colorInts[0] = uint256(1180162);
      colorInts[1] = uint256(7929858);
      colorInts[2] = uint256(7012357);
      colorInts[3] = uint256(16744737);
      colorIntCount = uint256(4);
    } else {
      colorInts[0] = uint256(197391);
      colorInts[1] = uint256(3604610);
      colorInts[2] = uint256(6553778);
      colorInts[3] = uint256(14305728);
      colorIntCount = uint256(4);
    }

    return (colorInts, colorIntCount);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import './TRUtils.sol';

/// @notice The Reliquary Constants
library TRKeys {

  struct RuneCore {
    uint256 tokenId;
    uint8 level;
    uint32 mana;
    bool isDivinityQuestLoot;
    bool isSecretDiscovered;
    uint8 secretsDiscovered;
    uint256 runeCode;
    string runeHash;
    string transmutation;
    address credit;
    uint256[] glyph;
    uint24[] colors;
    address metadataAddress;
    string hiddenLeyLines;
  }

  uint256 public constant FIRST_OPEN_VIBES_ID = 7778;
  address public constant VIBES_GENESIS = 0x6c7C97CaFf156473F6C9836522AE6e1d6448Abe7;
  address public constant VIBES_OPEN = 0xF3FCd0F025c21F087dbEB754516D2AD8279140Fc;

  uint8 public constant CURIO_SUPPLY = 64;
  uint256 public constant CURIO_TITHE = 80000000000000000; // 0.08 ETH

  uint32 public constant MANA_PER_YEAR = 100;
  uint32 public constant MANA_PER_YEAR_LV2 = 150;
  uint32 public constant SECONDS_PER_YEAR = 31536000;
  uint32 public constant MANA_FROM_REVELATION = 50;
  uint32 public constant MANA_FROM_DIVINATION = 50;
  uint32 public constant MANA_FROM_VIBRATION = 100;
  uint32 public constant MANA_COST_TO_UPGRADE = 150;

  uint256 public constant RELIC_SIZE = 64;
  uint256 public constant RELIC_SUPPLY = 1047;
  uint256 public constant TOTAL_SUPPLY = CURIO_SUPPLY + RELIC_SUPPLY;
  uint256 public constant RELIC_TITHE = 150000000000000000; // 0.15 ETH
  uint256 public constant INVENTORY_CAPACITY = 10;
  uint256 public constant BYTES_PER_RELICHASH = 3;
  uint256 public constant BYTES_PER_BLOCKHASH = 32;
  uint256 public constant HALF_POSSIBILITY_SPACE = (16**6) / 2;
  bytes32 public constant RELICHASH_MASK = 0x0000000000000000000000000000000000000000000000000000000000ffffff;
  uint256 public constant RELIC_DISCOUNT_GENESIS = 120000000000000000; // 0.12 ETH
  uint256 public constant RELIC_DISCOUNT_OPEN = 50000000000000000; // 0.05 ETH

  uint256 public constant RELIQUARY_CHAMBER_OUTSIDE = 0;
  uint256 public constant RELIQUARY_CHAMBER_GUARDIANS_HALL = 1;
  uint256 public constant RELIQUARY_CHAMBER_INNER_SANCTUM = 2;
  uint256 public constant RELIQUARY_CHAMBER_DIVINITYS_END = 3;
  uint256 public constant RELIQUARY_CHAMBER_CHAMPIONS_VAULT = 4;
  uint256 public constant ELEMENTAL_GUARDIAN_DNA = 88888888;
  uint256 public constant GRAIL_ID_NONE = 0;
  uint256 public constant GRAIL_ID_NATURE = 1;
  uint256 public constant GRAIL_ID_LIGHT = 2;
  uint256 public constant GRAIL_ID_WATER = 3;
  uint256 public constant GRAIL_ID_EARTH = 4;
  uint256 public constant GRAIL_ID_WIND = 5;
  uint256 public constant GRAIL_ID_ARCANE = 6;
  uint256 public constant GRAIL_ID_SHADOW = 7;
  uint256 public constant GRAIL_ID_FIRE = 8;
  uint256 public constant GRAIL_COUNT = 8;
  uint256 public constant GRAIL_DISTRIBUTION = 100;
  uint8 public constant SECRETS_OF_THE_GRAIL = 128;
  uint8 public constant MODE_TRANSMUTE_ELEMENT = 1;
  uint8 public constant MODE_CREATE_GLYPH = 2;
  uint8 public constant MODE_IMAGINE_COLORS = 3;

  uint256 public constant MAX_COLOR_INTS = 10;

  string public constant ROLL_ELEMENT = 'ELEMENT';
  string public constant ROLL_PALETTE = 'PALETTE';
  string public constant ROLL_SHUFFLE = 'SHUFFLE';
  string public constant ROLL_RED = 'RED';
  string public constant ROLL_GREEN = 'GREEN';
  string public constant ROLL_BLUE = 'BLUE';
  string public constant ROLL_REDSIGN = 'REDSIGN';
  string public constant ROLL_GREENSIGN = 'GREENSIGN';
  string public constant ROLL_BLUESIGN = 'BLUESIGN';
  string public constant ROLL_RANDOMCOLOR = 'RANDOMCOLOR';
  string public constant ROLL_RELICTYPE = 'RELICTYPE';
  string public constant ROLL_STYLE = 'STYLE';
  string public constant ROLL_COLORCOUNT = 'COLORCOUNT';
  string public constant ROLL_SPEED = 'SPEED';
  string public constant ROLL_GRAVITY = 'GRAVITY';
  string public constant ROLL_DISPLAY = 'DISPLAY';
  string public constant ROLL_GRAILS = 'GRAILS';
  string public constant ROLL_RUNEFLUX = 'RUNEFLUX';
  string public constant ROLL_CORRUPTION = 'CORRUPTION';

  string public constant RELIC_TYPE_GRAIL = 'Grail';
  string public constant RELIC_TYPE_CURIO = 'Curio';
  string public constant RELIC_TYPE_FOCUS = 'Focus';
  string public constant RELIC_TYPE_AMULET = 'Amulet';
  string public constant RELIC_TYPE_TALISMAN = 'Talisman';
  string public constant RELIC_TYPE_TRINKET = 'Trinket';

  string public constant GLYPH_TYPE_GRAIL = 'Origin';
  string public constant GLYPH_TYPE_CUSTOM = 'Divine';
  string public constant GLYPH_TYPE_NONE = 'None';

  string public constant ELEM_NATURE = 'Nature';
  string public constant ELEM_LIGHT = 'Light';
  string public constant ELEM_WATER = 'Water';
  string public constant ELEM_EARTH = 'Earth';
  string public constant ELEM_WIND = 'Wind';
  string public constant ELEM_ARCANE = 'Arcane';
  string public constant ELEM_SHADOW = 'Shadow';
  string public constant ELEM_FIRE = 'Fire';

  string public constant ANY_PAL_CUSTOM = 'Divine';

  string public constant NAT_PAL_JUNGLE = 'Jungle';
  string public constant NAT_PAL_CAMOUFLAGE = 'Camouflage';
  string public constant NAT_PAL_BIOLUMINESCENCE = 'Bioluminescence';

  string public constant NAT_ESS_FOREST = 'Forest';
  string public constant NAT_ESS_LIFE = 'Life';
  string public constant NAT_ESS_SWAMP = 'Swamp';
  string public constant NAT_ESS_WILDBLOOD = 'Wildblood';
  string public constant NAT_ESS_SOUL = 'Soul';

  string public constant LIG_PAL_PASTEL = 'Pastel';
  string public constant LIG_PAL_INFRARED = 'Infrared';
  string public constant LIG_PAL_ULTRAVIOLET = 'Ultraviolet';

  string public constant LIG_ESS_HEAVENLY = 'Heavenly';
  string public constant LIG_ESS_FAE = 'Fae';
  string public constant LIG_ESS_PRISMATIC = 'Prismatic';
  string public constant LIG_ESS_RADIANT = 'Radiant';
  string public constant LIG_ESS_PHOTONIC = 'Photonic';

  string public constant WAT_PAL_FROZEN = 'Frozen';
  string public constant WAT_PAL_DAWN = 'Dawn';
  string public constant WAT_PAL_OPALESCENT = 'Opalescent';

  string public constant WAT_ESS_TIDAL = 'Tidal';
  string public constant WAT_ESS_ARCTIC = 'Arctic';
  string public constant WAT_ESS_STORM = 'Storm';
  string public constant WAT_ESS_ILLUVIAL = 'Illuvial';
  string public constant WAT_ESS_UNDINE = 'Undine';

  string public constant EAR_PAL_COAL = 'Coal';
  string public constant EAR_PAL_SILVER = 'Silver';
  string public constant EAR_PAL_GOLD = 'Gold';

  string public constant EAR_ESS_MINERAL = 'Mineral';
  string public constant EAR_ESS_CRAGGY = 'Craggy';
  string public constant EAR_ESS_DWARVEN = 'Dwarven';
  string public constant EAR_ESS_GNOMIC = 'Gnomic';
  string public constant EAR_ESS_CRYSTAL = 'Crystal';

  string public constant WIN_PAL_BERRY = 'Berry';
  string public constant WIN_PAL_THUNDER = 'Thunder';
  string public constant WIN_PAL_AERO = 'Aero';

  string public constant WIN_ESS_SYLPHIC = 'Sylphic';
  string public constant WIN_ESS_VISCERAL = 'Visceral';
  string public constant WIN_ESS_FROSTED = 'Frosted';
  string public constant WIN_ESS_ELECTRIC = 'Electric';
  string public constant WIN_ESS_MAGNETIC = 'Magnetic';

  string public constant ARC_PAL_FROSTFIRE = 'Frostfire';
  string public constant ARC_PAL_COSMIC = 'Cosmic';
  string public constant ARC_PAL_COLORLESS = 'Colorless';

  string public constant ARC_ESS_MAGIC = 'Magic';
  string public constant ARC_ESS_ASTRAL = 'Astral';
  string public constant ARC_ESS_FORBIDDEN = 'Forbidden';
  string public constant ARC_ESS_RUNIC = 'Runic';
  string public constant ARC_ESS_UNKNOWN = 'Unknown';

  string public constant SHA_PAL_DARKNESS = 'Darkness';
  string public constant SHA_PAL_VOID = 'Void';
  string public constant SHA_PAL_UNDEAD = 'Undead';

  string public constant SHA_ESS_NIGHT = 'Night';
  string public constant SHA_ESS_FORGOTTEN = 'Forgotten';
  string public constant SHA_ESS_ABYSSAL = 'Abyssal';
  string public constant SHA_ESS_EVIL = 'Evil';
  string public constant SHA_ESS_LOST = 'Lost';

  string public constant FIR_PAL_HEAT = 'Heat';
  string public constant FIR_PAL_EMBER = 'Ember';
  string public constant FIR_PAL_CORRUPTED = 'Corrupted';

  string public constant FIR_ESS_INFERNAL = 'Infernal';
  string public constant FIR_ESS_MOLTEN = 'Molten';
  string public constant FIR_ESS_ASHEN = 'Ashen';
  string public constant FIR_ESS_DRACONIC = 'Draconic';
  string public constant FIR_ESS_CELESTIAL = 'Celestial';

  string public constant STYLE_SMOOTH = 'Smooth';
  string public constant STYLE_PAJAMAS = 'Pajamas';
  string public constant STYLE_SILK = 'Silk';
  string public constant STYLE_SKETCH = 'Sketch';

  string public constant SPEED_ZEN = 'Zen';
  string public constant SPEED_TRANQUIL = 'Tranquil';
  string public constant SPEED_NORMAL = 'Normal';
  string public constant SPEED_FAST = 'Fast';
  string public constant SPEED_SWIFT = 'Swift';
  string public constant SPEED_HYPER = 'Hyper';

  string public constant GRAV_LUNAR = 'Lunar';
  string public constant GRAV_ATMOSPHERIC = 'Atmospheric';
  string public constant GRAV_LOW = 'Low';
  string public constant GRAV_NORMAL = 'Normal';
  string public constant GRAV_HIGH = 'High';
  string public constant GRAV_MASSIVE = 'Massive';
  string public constant GRAV_STELLAR = 'Stellar';
  string public constant GRAV_GALACTIC = 'Galactic';

  string public constant DISPLAY_NORMAL = 'Normal';
  string public constant DISPLAY_MIRRORED = 'Mirrored';
  string public constant DISPLAY_UPSIDEDOWN = 'UpsideDown';
  string public constant DISPLAY_MIRROREDUPSIDEDOWN = 'MirroredUpsideDown';

}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

/// @notice The Reliquary Utility Methods
library TRUtils {

  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getColorCode(uint256 color) public pure returns (string memory) {
    bytes16 hexChars = '0123456789abcdef';
    uint256 r1 = (color >> uint256(20)) & uint256(15);
    uint256 r2 = (color >> uint256(16)) & uint256(15);
    uint256 g1 = (color >> uint256(12)) & uint256(15);
    uint256 g2 = (color >> uint256(8)) & uint256(15);
    uint256 b1 = (color >> uint256(4)) & uint256(15);
    uint256 b2 = color & uint256(15);
    bytes memory code = new bytes(6);
    code[0] = hexChars[r1];
    code[1] = hexChars[r2];
    code[2] = hexChars[g1];
    code[3] = hexChars[g2];
    code[4] = hexChars[b1];
    code[5] = hexChars[b2];
    return string(code);
  }

  function compare(string memory a, string memory b) public pure returns (bool) {
    if (bytes(a).length != bytes(b).length) {
      return false;
    } else {
      return keccak256(bytes(a)) == keccak256(bytes(b));
    }
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  // https://ethereum.stackexchange.com/a/8447
  function toAsciiString(address x) public pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  // https://stackoverflow.com/a/69302348/424107
  function toCapsHexString(uint256 i) internal pure returns (string memory) {
    if (i == 0) return '0';
    uint j = i;
    uint length;
    while (j != 0) {
      length++;
      j = j >> 4;
    }
    uint mask = 15;
    bytes memory bstr = new bytes(length);
    uint k = length;
    while (i != 0) {
      uint curr = (i & mask);
      bstr[--k] = curr > 9 ?
        bytes1(uint8(55 + curr)) :
        bytes1(uint8(48 + curr)); // 55 = 65 - 10
      i = i >> 4;
    }
    return string(bstr);
  }

}