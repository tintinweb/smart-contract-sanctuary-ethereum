// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsClothing.sol";
import "../Gene.sol";

library OptionClothing {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 clothes = Gene.getGene(TraitDefs.CLOTHING, dna);
    uint16 variant = clothes % 106;

    if (variant == 0) {
      return TraitOptionsClothing.BLUE_ERC20_SHIRT;
    } else if (variant == 1) {
      return TraitOptionsClothing.BLUE_FOX_WALLET_TANKTOP;
    } else if (variant == 2) {
      return TraitOptionsClothing.BLUE_GRADIENT_DIAMOND_SHIRT;
    } else if (variant == 3) {
      return TraitOptionsClothing.BLUE_LINK_SHIRT;
    } else if (variant == 4) {
      return TraitOptionsClothing.BLUE_WEB3_SAFE_SHIRT;
    } else if (variant == 5) {
      return TraitOptionsClothing.RED_ERC20_SHIRT;
    } else if (variant == 6) {
      return TraitOptionsClothing.RED_FOX_WALLET_TANKTOP;
    } else if (variant == 7) {
      return TraitOptionsClothing.RED_GRADIENT_DIAMOND_SHIRT;
    } else if (variant == 8) {
      return TraitOptionsClothing.RED_LINK_SHIRT;
    } else if (variant == 9) {
      return TraitOptionsClothing.RED_WEB3_SAFE_SHIRT;
    } else if (variant == 10) {
      return TraitOptionsClothing.ADAMS_LEAF;
    } else if (variant == 11) {
      return TraitOptionsClothing.BLACK_BELT;
    } else if (variant == 12) {
      return TraitOptionsClothing.BLACK_LEATHER_JACKET;
    } else if (variant == 13) {
      return TraitOptionsClothing.BLACK_TUXEDO;
    } else if (variant == 14) {
      return TraitOptionsClothing.BLACK_AND_BLUE_STRIPED_BIB;
    } else if (variant == 15) {
      return TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
    } else if (variant == 16) {
      return TraitOptionsClothing.BLACK_WITH_BLUE_DRESS;
    } else if (variant == 17) {
      return TraitOptionsClothing.BLACK_WITH_BLUE_STRIPES_TANKTOP;
    } else if (variant == 18) {
      return TraitOptionsClothing.BLUE_BEAR_LOVE_SHIRT;
    } else if (variant == 19) {
      return TraitOptionsClothing.BLUE_BEAR_MARKET_SHIRT;
    } else if (variant == 20) {
      return TraitOptionsClothing.BLUE_BULL_MARKET_SHIRT;
    } else if (variant == 21) {
      return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_DOTS;
    } else if (variant == 22) {
      return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_LACE;
    } else if (variant == 23) {
      return TraitOptionsClothing.BLUE_DRESS;
    } else if (variant == 24) {
      return TraitOptionsClothing.BLUE_ETH_SHIRT;
    } else if (variant == 25) {
      return TraitOptionsClothing.BLUE_FANNY_PACK;
    } else if (variant == 26) {
      return TraitOptionsClothing.BLUE_HOOLA_HOOP;
    } else if (variant == 27) {
      return TraitOptionsClothing.BLUE_HOOT_SHIRT;
    } else if (variant == 28) {
      return TraitOptionsClothing.BLUE_JESTERS_COLLAR;
    } else if (variant == 29) {
      return TraitOptionsClothing.BLUE_KNIT_SWEATER;
    } else if (variant == 30) {
      return TraitOptionsClothing.BLUE_LEG_WARMERS;
    } else if (variant == 31) {
      return TraitOptionsClothing.BLUE_OVERALLS;
    } else if (variant == 32) {
      return TraitOptionsClothing.BLUE_PINK_UNICORN_DEX_TANKTOP;
    } else if (variant == 33) {
      return TraitOptionsClothing.BLUE_PONCHO;
    } else if (variant == 34) {
      return TraitOptionsClothing.BLUE_PORTAL_SHIRT;
    } else if (variant == 35) {
      return TraitOptionsClothing.BLUE_PROOF_OF_STAKE_SHIRT;
    } else if (variant == 36) {
      return TraitOptionsClothing.BLUE_PROOF_OF_WORK_SHIRT;
    } else if (variant == 37) {
      return TraitOptionsClothing.BLUE_PUFFY_VEST;
    } else if (variant == 38) {
      return TraitOptionsClothing.BLUE_REKT_SHIRT;
    } else if (variant == 39) {
      return TraitOptionsClothing.BLUE_RASPBERRY_PI_NODE_TANKTOP;
    } else if (variant == 40) {
      return TraitOptionsClothing.BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
    } else if (variant == 41) {
      return TraitOptionsClothing.BLUE_SKIRT;
    } else if (variant == 42) {
      return TraitOptionsClothing.BLUE_STRIPED_NECKTIE;
    } else if (variant == 43) {
      return TraitOptionsClothing.BLUE_SUIT_JACKET_WITH_GOLD_TIE;
    } else if (variant == 44) {
      return TraitOptionsClothing.BLUE_TANKTOP;
    } else if (variant == 45) {
      return TraitOptionsClothing.BLUE_TOGA;
    } else if (variant == 46) {
      return TraitOptionsClothing.BLUE_TUBE_TOP;
    } else if (variant == 47) {
      return TraitOptionsClothing.BLUE_VEST;
    } else if (variant == 48) {
      return TraitOptionsClothing.BLUE_WAGMI_SHIRT;
    } else if (variant == 49) {
      return TraitOptionsClothing.BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
    } else if (variant == 50) {
      return TraitOptionsClothing.BLUE_WITH_PINK_AND_GREEN_DRESS;
    } else if (variant == 51) {
      return TraitOptionsClothing.BLUE_WITH_WHITE_APRON;
    } else if (variant == 52) {
      return TraitOptionsClothing.BORAT_SWIMSUIT;
    } else if (variant == 53) {
      return TraitOptionsClothing.BUTTERFLY_WINGS;
    } else if (variant == 54) {
      return TraitOptionsClothing.DUSTY_MAROON_MINERS_GARB;
    } else if (variant == 55) {
      return TraitOptionsClothing.DUSTY_NAVY_MINERS_GARB;
    } else if (variant == 56) {
      return TraitOptionsClothing.GRASS_SKIRT;
    } else if (variant == 57) {
      return TraitOptionsClothing.LEDERHOSEN;
    } else if (variant == 58) {
      return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
    } else if (variant == 59) {
      return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_RED_CAPE;
    } else if (variant == 60) {
      return TraitOptionsClothing.NAKEY;
    } else if (variant == 61) {
      return TraitOptionsClothing.NODE_OPERATORS_VEST;
    } else if (variant == 62) {
      return TraitOptionsClothing.ORANGE_INFLATABLE_WATER_WINGS;
    } else if (variant == 63) {
      return TraitOptionsClothing.ORANGE_PRISON_UNIFORM;
    } else if (variant == 64) {
      return TraitOptionsClothing.PINK_TUTU;
    } else if (variant == 65) {
      return TraitOptionsClothing.PINK_AND_TEAL_DEFI_LENDING_TANKTOP;
    } else if (variant == 66) {
      return TraitOptionsClothing.RED_BEAR_LOVE_SHIRT;
    } else if (variant == 67) {
      return TraitOptionsClothing.RED_BEAR_MARKET_SHIRT;
    } else if (variant == 68) {
      return TraitOptionsClothing.RED_BULL_MARKET_SHIRT;
    } else if (variant == 69) {
      return TraitOptionsClothing.RED_DRESS_WITH_WHITE_DOTS;
    } else if (variant == 70) {
      return TraitOptionsClothing.RED_DRESS_WITH_WHITE_LACE;
    } else if (variant == 71) {
      return TraitOptionsClothing.RED_DRESS;
    } else if (variant == 72) {
      return TraitOptionsClothing.RED_ETH_SHIRT;
    } else if (variant == 73) {
      return TraitOptionsClothing.RED_FANNY_PACK;
    } else if (variant == 74) {
      return TraitOptionsClothing.RED_HOOLA_HOOP;
    } else if (variant == 75) {
      return TraitOptionsClothing.RED_HOOT_SHIRT;
    } else if (variant == 76) {
      return TraitOptionsClothing.RED_JESTERS_COLLAR;
    } else if (variant == 77) {
      return TraitOptionsClothing.RED_KNIT_SWEATER;
    } else if (variant == 78) {
      return TraitOptionsClothing.RED_LEG_WARMERS;
    } else if (variant == 79) {
      return TraitOptionsClothing.RED_OVERALLS;
    } else if (variant == 80) {
      return TraitOptionsClothing.RED_PINK_UNICORN_DEX_TANKTOP;
    } else if (variant == 81) {
      return TraitOptionsClothing.RED_PONCHO;
    } else if (variant == 82) {
      return TraitOptionsClothing.RED_PORTAL_SHIRT;
    } else if (variant == 83) {
      return TraitOptionsClothing.RED_PROOF_OF_STAKE_SHIRT;
    } else if (variant == 84) {
      return TraitOptionsClothing.RED_PROOF_OF_WORK_SHIRT;
    } else if (variant == 85) {
      return TraitOptionsClothing.RED_PUFFY_VEST;
    } else if (variant == 86) {
      return TraitOptionsClothing.RED_REKT_SHIRT;
    } else if (variant == 87) {
      return TraitOptionsClothing.RED_RASPBERRY_PI_NODE_TANKTOP;
    } else if (variant == 88) {
      return TraitOptionsClothing.RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
    } else if (variant == 89) {
      return TraitOptionsClothing.RED_SKIRT;
    } else if (variant == 90) {
      return TraitOptionsClothing.RED_STRIPED_NECKTIE;
    } else if (variant == 91) {
      return TraitOptionsClothing.RED_SUIT_JACKET_WITH_GOLD_TIE;
    } else if (variant == 92) {
      return TraitOptionsClothing.RED_TANKTOP;
    } else if (variant == 93) {
      return TraitOptionsClothing.RED_TOGA;
    } else if (variant == 94) {
      return TraitOptionsClothing.RED_TUBE_TOP;
    } else if (variant == 95) {
      return TraitOptionsClothing.RED_VEST;
    } else if (variant == 96) {
      return TraitOptionsClothing.RED_WAGMI_SHIRT;
    } else if (variant == 97) {
      return TraitOptionsClothing.RED_WITH_PINK_AND_GREEN_DRESS;
    } else if (variant == 98) {
      return TraitOptionsClothing.RED_WITH_WHITE_APRON;
    } else if (variant == 99) {
      return TraitOptionsClothing.RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
    } else if (variant == 100) {
      return TraitOptionsClothing.TAN_CARGO_SHORTS;
    } else if (variant == 101) {
      return TraitOptionsClothing.VAMPIRE_BAT_WINGS;
    } else if (variant == 102) {
      return TraitOptionsClothing.WHITE_TUXEDO;
    } else if (variant == 103) {
      return TraitOptionsClothing.WHITE_AND_RED_STRIPED_BIB;
    } else if (variant == 104) {
      return TraitOptionsClothing.WHITE_WITH_RED_DRESS;
    } else if (variant == 105) {
      return TraitOptionsClothing.WHITE_WITH_RED_STRIPES_TANKTOP;
    }
    return TraitOptionsClothing.RED_ETH_SHIRT;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitDefs {
  uint8 constant SPECIES = 0;
  uint8 constant LOCALE = 1;
  uint8 constant BELLY = 2;
  uint8 constant ARMS = 3;
  uint8 constant EYES = 4;
  uint8 constant MOUTH = 5;
  uint8 constant NOSE = 6;
  uint8 constant CLOTHING = 7;
  uint8 constant HAT = 8;
  uint8 constant JEWELRY = 9;
  uint8 constant FOOTWEAR = 10;
  uint8 constant ACCESSORIES = 11;
  uint8 constant FACE_ACCESSORY = 12;
  uint8 constant BACKGROUND = 13;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsClothing {
  uint8 constant BLUE_ERC20_SHIRT = 0;
  uint8 constant BLUE_FOX_WALLET_TANKTOP = 1;
  uint8 constant BLUE_GRADIENT_DIAMOND_SHIRT = 2;
  uint8 constant BLUE_LINK_SHIRT = 3;
  uint8 constant BLUE_WEB3_SAFE_SHIRT = 4;
  uint8 constant RED_ERC20_SHIRT = 5;
  uint8 constant RED_FOX_WALLET_TANKTOP = 6;
  uint8 constant RED_GRADIENT_DIAMOND_SHIRT = 7;
  uint8 constant RED_LINK_SHIRT = 8;
  uint8 constant RED_WEB3_SAFE_SHIRT = 9;
  uint8 constant ADAMS_LEAF = 10;
  uint8 constant BLACK_BELT = 11;
  uint8 constant BLACK_LEATHER_JACKET = 12;
  uint8 constant BLACK_TUXEDO = 13;
  uint8 constant BLACK_AND_BLUE_STRIPED_BIB = 14;
  uint8 constant BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM = 15;
  uint8 constant BLACK_WITH_BLUE_DRESS = 16;
  uint8 constant BLACK_WITH_BLUE_STRIPES_TANKTOP = 17;
  uint8 constant BLUE_BEAR_LOVE_SHIRT = 18;
  uint8 constant BLUE_BEAR_MARKET_SHIRT = 19;
  uint8 constant BLUE_BULL_MARKET_SHIRT = 20;
  uint8 constant BLUE_DRESS_WITH_WHITE_DOTS = 21;
  uint8 constant BLUE_DRESS_WITH_WHITE_LACE = 22;
  uint8 constant BLUE_DRESS = 23;
  uint8 constant BLUE_ETH_SHIRT = 24;
  uint8 constant BLUE_FANNY_PACK = 25;
  uint8 constant BLUE_HOOLA_HOOP = 26;
  uint8 constant BLUE_HOOT_SHIRT = 27;
  uint8 constant BLUE_JESTERS_COLLAR = 28;
  uint8 constant BLUE_KNIT_SWEATER = 29;
  uint8 constant BLUE_LEG_WARMERS = 30;
  uint8 constant BLUE_OVERALLS = 31;
  uint8 constant BLUE_PINK_UNICORN_DEX_TANKTOP = 32;
  uint8 constant BLUE_PONCHO = 33;
  uint8 constant BLUE_PORTAL_SHIRT = 34;
  uint8 constant BLUE_PROOF_OF_STAKE_SHIRT = 35;
  uint8 constant BLUE_PROOF_OF_WORK_SHIRT = 36;
  uint8 constant BLUE_PUFFY_VEST = 37;
  uint8 constant BLUE_REKT_SHIRT = 38;
  uint8 constant BLUE_RASPBERRY_PI_NODE_TANKTOP = 39;
  uint8 constant BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS = 40;
  uint8 constant BLUE_SKIRT = 41;
  uint8 constant BLUE_STRIPED_NECKTIE = 42;
  uint8 constant BLUE_SUIT_JACKET_WITH_GOLD_TIE = 43;
  uint8 constant BLUE_TANKTOP = 44;
  uint8 constant BLUE_TOGA = 45;
  uint8 constant BLUE_TUBE_TOP = 46;
  uint8 constant BLUE_VEST = 47;
  uint8 constant BLUE_WAGMI_SHIRT = 48;
  uint8 constant BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY = 49;
  uint8 constant BLUE_WITH_PINK_AND_GREEN_DRESS = 50;
  uint8 constant BLUE_WITH_WHITE_APRON = 51;
  uint8 constant BORAT_SWIMSUIT = 52;
  uint8 constant BUTTERFLY_WINGS = 53;
  uint8 constant DUSTY_MAROON_MINERS_GARB = 54;
  uint8 constant DUSTY_NAVY_MINERS_GARB = 55;
  uint8 constant GRASS_SKIRT = 56;
  uint8 constant LEDERHOSEN = 57;
  uint8 constant MAGICIAN_UNIFORM_WITH_BLUE_CAPE = 58;
  uint8 constant MAGICIAN_UNIFORM_WITH_RED_CAPE = 59;
  uint8 constant NAKEY = 60;
  uint8 constant NODE_OPERATORS_VEST = 61;
  uint8 constant ORANGE_INFLATABLE_WATER_WINGS = 62;
  uint8 constant ORANGE_PRISON_UNIFORM = 63;
  uint8 constant PINK_TUTU = 64;
  uint8 constant PINK_AND_TEAL_DEFI_LENDING_TANKTOP = 65;
  uint8 constant RED_BEAR_LOVE_SHIRT = 66;
  uint8 constant RED_BEAR_MARKET_SHIRT = 67;
  uint8 constant RED_BULL_MARKET_SHIRT = 68;
  uint8 constant RED_DRESS_WITH_WHITE_DOTS = 69;
  uint8 constant RED_DRESS_WITH_WHITE_LACE = 70;
  uint8 constant RED_DRESS = 71;
  uint8 constant RED_ETH_SHIRT = 72;
  uint8 constant RED_FANNY_PACK = 73;
  uint8 constant RED_HOOLA_HOOP = 74;
  uint8 constant RED_HOOT_SHIRT = 75;
  uint8 constant RED_JESTERS_COLLAR = 76;
  uint8 constant RED_KNIT_SWEATER = 77;
  uint8 constant RED_LEG_WARMERS = 78;
  uint8 constant RED_OVERALLS = 79;
  uint8 constant RED_PINK_UNICORN_DEX_TANKTOP = 80;
  uint8 constant RED_PONCHO = 81;
  uint8 constant RED_PORTAL_SHIRT = 82;
  uint8 constant RED_PROOF_OF_STAKE_SHIRT = 83;
  uint8 constant RED_PROOF_OF_WORK_SHIRT = 84;
  uint8 constant RED_PUFFY_VEST = 85;
  uint8 constant RED_REKT_SHIRT = 86;
  uint8 constant RED_RASPBERRY_PI_NODE_TANKTOP = 87;
  uint8 constant RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS = 88;
  uint8 constant RED_SKIRT = 89;
  uint8 constant RED_STRIPED_NECKTIE = 90;
  uint8 constant RED_SUIT_JACKET_WITH_GOLD_TIE = 91;
  uint8 constant RED_TANKTOP = 92;
  uint8 constant RED_TOGA = 93;
  uint8 constant RED_TUBE_TOP = 94;
  uint8 constant RED_VEST = 95;
  uint8 constant RED_WAGMI_SHIRT = 96;
  uint8 constant RED_WITH_PINK_AND_GREEN_DRESS = 97;
  uint8 constant RED_WITH_WHITE_APRON = 98;
  uint8 constant RED_WITH_WHITE_STRIPES_SOCCER_JERSEY = 99;
  uint8 constant TAN_CARGO_SHORTS = 100;
  uint8 constant VAMPIRE_BAT_WINGS = 101;
  uint8 constant WHITE_TUXEDO = 102;
  uint8 constant WHITE_AND_RED_STRIPED_BIB = 103;
  uint8 constant WHITE_WITH_RED_DRESS = 104;
  uint8 constant WHITE_WITH_RED_STRIPES_TANKTOP = 105;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library Gene {
  function getGene(uint8 traitDef, uint256 dna) internal pure returns (uint16) {
    // type(uint16).max
    // right shift traitDef * 16, then bitwise & with the max 16 bit number
    return uint16((dna >> (traitDef * 16)) & uint256(type(uint16).max));
  }
}