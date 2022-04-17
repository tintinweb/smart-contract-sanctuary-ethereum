// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import './TRKeys.sol';

/// @notice The Reliquary Grail of Arcane
library TRGrailArcane {

  function getElement() public pure returns (string memory) {
    return 'Arcane';
  }

  function getPalette() public pure returns (string memory) {
    return 'Cosmic';
  }

  function getEssence() public pure returns (string memory) {
    return 'Unknown';
  }

  function getStyle() public pure returns (string memory) {
    return 'Pajamas';
  }

  function getSpeed() public pure returns (string memory) {
    return 'Swift';
  }

  function getGravity() public pure returns (string memory) {
    return 'Massive';
  }

  function getDisplay() public pure returns (string memory) {
    return 'Normal';
  }

  function getColorCount() public pure returns (uint256) {
    return 5;
  }

  function getRelicType() public pure returns (string memory) {
    return TRKeys.RELIC_TYPE_GRAIL;
  }

  function getRuneflux() public pure returns (uint256) {
    return 800;
  }

  function getCorruption() public pure returns (uint256) {
    return 150;
  }

  function getGlyph() public pure returns (uint256[] memory) {
    uint256[] memory glyph = new uint256[](64);
    glyph[0]  = uint256(1111111111111111111111000000000000000000000000000000);
    glyph[1]  = uint256(1111111111111111111111000000000000000000000000000000);
    glyph[2]  = uint256(111111111111111111111100000000000000000000000000000000);
    glyph[3]  = uint256(111111111111111111111100000000000000000000000000000000);
    glyph[4]  = uint256(11111111111111111111110000000000000000000000000000000000);
    glyph[5]  = uint256(11111111111111111111110000000000000000000000000000000000);
    glyph[6]  = uint256(1111111111111111111111000000000000000000000000000000000000);
    glyph[7]  = uint256(1111111111111111111111000000000000000000000000000000000000);
    glyph[8]  = uint256(111111111111111111111100000000000000000000000000000000000000);
    glyph[9]  = uint256(111111111111111111111100000000000000000000000000000000000000);
    glyph[10] = uint256(11111111111111111111119999999999999999000000000000000000000000);
    glyph[11] = uint256(11111111111111111111119999999999999999000000000000000000000000);
    glyph[12] = uint256(1111111111111111111199990000000000000000999900000000000000000000);
    glyph[13] = uint256(1111111111111111111199990000000000000000999900000000000000000000);
    glyph[14] = uint256(1111111111111111119900000000000000000000000099000000000000000000);
    glyph[15] = uint256(1111111111111111119900000000000000000000000099000000000000000000);
    glyph[16] = uint256(1111111111111111119944666666444444446666664499000000000000000000);
    glyph[17] = uint256(1111111111111111119944666666444444446666664499000000000000000000);
    glyph[18] = uint256(1111111111111188664477777755660000667777775544668800000000000000);
    glyph[19] = uint256(1111111111111188664477777755660000667777775544668800000000000000);
    glyph[20] = uint256(1111111111111188886677775555776666777755557766888800000000000000);
    glyph[21] = uint256(1111111111111188886677775555776666777755557766888800000000000000);
    glyph[22] = uint256(1111111111110000996655557777776666555577777766990000000000000000);
    glyph[23] = uint256(1111111111110000996655557777776666555577777766990000000000000000);
    glyph[24] = uint256(1111111111000000990044557777440000445577884400990000000000000000);
    glyph[25] = uint256(1111111111000000990044557777440000445577884400990000000000000000);
    glyph[26] = uint256(1111111100000000990000444444000000004444440000990000000000000000);
    glyph[27] = uint256(1111111100000000990000444444000000004444440000990000000000000000);
    glyph[28] = uint256(1111110000000000990099999999000000009999999900990000000000000000);
    glyph[29] = uint256(1111110000000000990099999999000000009999999900990000000000000000);
    glyph[30] = uint256(1111000000005599996666666666666600666666666666999955000000000000);
    glyph[31] = uint256(1111000000005599996666666666666600666666666666999955000000000000);
    glyph[32] = uint256(1100000000009933996699999999666666669999999966993399000000000000);
    glyph[33] = uint256(1100000000009933996699999999666666669999999966993399000000000000);
    glyph[34] = uint256(449933996666009900996666993399336666993399440000000000);
    glyph[35] = uint256(449933996666009900996666993399336666993399440000000000);
    glyph[36] = uint256(9933996666666666666666666666666666993399000000000000);
    glyph[37] = uint256(9933996666666666666666666666666666993399000000000000);
    glyph[38] = uint256(449933998888888888888899999999999999993399440000000000);
    glyph[39] = uint256(449933998888888888888899999999999999993399440000000000);
    glyph[40] = uint256(99998888888888889999999999999999999900000000000000);
    glyph[41] = uint256(99998888888888889999999999999999999900000000000000);
    glyph[42] = uint256(998888888888888899999999999999990000000000000000);
    glyph[43] = uint256(998888888888888899999999999999990000000000000000);
    glyph[44] = uint256(998888888888888899999999999999990000000000000011);
    glyph[45] = uint256(998888888888888899999999999999990000000000000011);
    glyph[46] = uint256(9988888888888899999999999999000000000000001111);
    glyph[47] = uint256(9988888888888899999999999999000000000000001111);
    glyph[48] = uint256(9988888888888899999999999999000000000000111111);
    glyph[49] = uint256(9988888888888899999999999999000000000000111111);
    glyph[50] = uint256(99888888888899999999999900000000000011111111);
    glyph[51] = uint256(99888888888899999999999900000000000011111111);
    glyph[52] = uint256(99998888888899999999999900000000001111111111);
    glyph[53] = uint256(99998888888899999999999900000000001111111111);
    glyph[54] = uint256(99999988888899999999999900000000111111111111);
    glyph[55] = uint256(99999988888899999999999900000000111111111111);
    glyph[56] = uint256(9999999999888899999999999999000011111111111111);
    glyph[57] = uint256(9999999999888899999999999999000011111111111111);
    glyph[58] = uint256(999999999999999999999999999999991111111111111111);
    glyph[59] = uint256(999999999999999999999999999999991111111111111111);
    glyph[60] = uint256(99999999999988888899999999999999999911111111111111);
    glyph[61] = uint256(99999999999988888899999999999999999911111111111111);
    glyph[62] = uint256(9999999999998888888899999999999999999999111111111111);
    glyph[63] = uint256(9999999999998888888899999999999999999999111111111111);
    return glyph;
  }

  function getDescription() public pure returns (string memory) {
    return "The Grail of Arcane honors the Chain Runners for building an awesome on-chain community and for their commitment to openly building great experiences around their nascent cyberpunk universe. This piece recreates Runner #6923, submitted by Tiamat.";
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