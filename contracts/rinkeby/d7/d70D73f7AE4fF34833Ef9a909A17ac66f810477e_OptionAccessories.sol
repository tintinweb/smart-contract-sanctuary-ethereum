// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsAccessories.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "./OptionSpecies.sol";
import "../Gene.sol";

library OptionAccessories {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 accessory = Gene.getGene(TraitDefs.ACCESSORIES, dna);
    // uint16 variant = accessory % 40;
    uint16 rarityRoll = accessory % 4050;
    uint8 species = OptionSpecies.getOption(dna);

    // 1(1000) + 22(100) + 12(50) + 5(50)
    // 1000 + 2200 + 600 + 250
    // 4050

    if (rarityRoll < 1000) {
      return TraitOptionsAccessories.NONE;
    } else if (rarityRoll >= 1000 && rarityRoll < 3200) {
      // return 100 weight
      uint16 coinFlip = rarityRoll % 2;
      uint16 variant = rarityRoll % 17;

      // if BLACK or panda
      if (species != TraitOptionsSpecies.POLAR && coinFlip == 0) {
        if (variant == 0) {
          return TraitOptionsAccessories.BLUE_BALLOON;
        } else if (variant == 1) {
          return TraitOptionsAccessories.BLUE_BOXING_GLOVES;
        } else if (variant == 2) {
          return TraitOptionsAccessories.BLUE_FINGERNAIL_POLISH;
        } else if (variant == 3) {
          return TraitOptionsAccessories.BLUE_GARDENER_TROWEL;
        } else if (variant == 4) {
          return TraitOptionsAccessories.BLUE_MERGE_BEARS_FOAM_FINGER;
        } else if (variant == 5) {
          return TraitOptionsAccessories.BLUE_PURSE;
        } else if (variant == 6) {
          return TraitOptionsAccessories.BLUE_SPATULA;
        } else if (variant == 7) {
          return TraitOptionsAccessories.BUCKET_OF_BLUE_PAINT;
        } else if (variant == 8) {
          return TraitOptionsAccessories.HAND_IN_A_BLUE_COOKIE_JAR;
        } else if (variant == 9) {
          return
            TraitOptionsAccessories.PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET;
        }
      }

      if (species != TraitOptionsSpecies.BLACK && coinFlip == 1) {
        // if polar or panda
        if (variant == 0) {
          return TraitOptionsAccessories.BUCKET_OF_RED_PAINT;
        } else if (variant == 1) {
          return TraitOptionsAccessories.HAND_IN_A_RED_COOKIE_JAR;
        } else if (variant == 2) {
          return
            TraitOptionsAccessories.PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET;
        } else if (variant == 3) {
          return TraitOptionsAccessories.RED_BALLOON;
        } else if (variant == 4) {
          return TraitOptionsAccessories.RED_BOXING_GLOVES;
        } else if (variant == 5) {
          return TraitOptionsAccessories.RED_FINGERNAIL_POLISH;
        } else if (variant == 6) {
          return TraitOptionsAccessories.RED_GARDENER_TROWEL;
        } else if (variant == 7) {
          return TraitOptionsAccessories.RED_MERGE_BEARS_FOAM_FINGER;
        } else if (variant == 8) {
          return TraitOptionsAccessories.RED_PURSE;
        } else if (variant == 9) {
          return TraitOptionsAccessories.RED_SPATULA;
        }
      }

      if (variant == 10) {
        return TraitOptionsAccessories.PINK_FINGERNAIL_POLISH;
      } else if (variant == 11) {
        return TraitOptionsAccessories.PINK_PURSE;
      } else if (variant == 12) {
        return TraitOptionsAccessories.BANHAMMER;
      } else if (variant == 13) {
        return TraitOptionsAccessories.BEEHIVE_ON_A_STICK;
      } else if (variant == 14) {
        return TraitOptionsAccessories.DOUBLE_DUMBBELLS;
      } else if (variant == 15) {
        return TraitOptionsAccessories.TOILET_PAPER;
      } else if (variant == 16) {
        return TraitOptionsAccessories.WOODEN_WALKING_CANE;
      }
    } else if (rarityRoll >= 3200 && rarityRoll < 3800) {
      uint16 variant = rarityRoll % 17;

      // return 50 weight
      if (variant == 0) {
        return TraitOptionsAccessories.BALL_AND_CHAIN;
      } else if (variant == 1) {
        return TraitOptionsAccessories.BAMBOO_SWORD;
      }
      if (
        variant == 2 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.BASKET_OF_EXCESS_USED_GRAPHICS_CARDS;
      } else if (
        variant == 3 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.BURNED_OUT_GRAPHICS_CARD;
      } else if (
        variant == 4 &&
        species != TraitOptionsSpecies.PANDA &&
        species != TraitOptionsSpecies.REVERSE_PANDA &&
        species != TraitOptionsSpecies.GOLD_PANDA
      ) {
        return TraitOptionsAccessories.MINERS_PICKAXE;
      } else if (variant == 5) {
        return TraitOptionsAccessories.NINJA_SWORDS;
      } else if (
        variant == 6 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.PROOF_OF_RIBEYE_STEAK;
      } else if (variant == 7) {
        return TraitOptionsAccessories.FRESH_SALMON;
      }
    } else if (rarityRoll >= 3800) {
      uint16 variant = rarityRoll % 4;

      // return 25 weight
      if (variant == 0) {
        return TraitOptionsAccessories.PHISHING_NET;
      } else if (variant == 1) {
        return TraitOptionsAccessories.PHISHING_ROD;
      }
      if (variant == 2) {
        return TraitOptionsAccessories.COLD_STORAGE_WALLET;
      } else if (variant == 3) {
        return TraitOptionsAccessories.HOT_WALLET;
      }
    }
    return TraitOptionsAccessories.NONE;
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

library TraitOptionsAccessories {
  uint8 constant BALL_AND_CHAIN = 0;
  uint8 constant BAMBOO_SWORD = 1;
  uint8 constant BANHAMMER = 2;
  uint8 constant BASKET_OF_EXCESS_USED_GRAPHICS_CARDS = 3;
  uint8 constant BEEHIVE_ON_A_STICK = 4;
  uint8 constant BLUE_BALLOON = 5;
  uint8 constant BLUE_BOXING_GLOVES = 6;
  uint8 constant BLUE_FINGERNAIL_POLISH = 7;
  uint8 constant BLUE_GARDENER_TROWEL = 8;
  uint8 constant BLUE_MERGE_BEARS_FOAM_FINGER = 9;
  uint8 constant BLUE_PURSE = 10;
  uint8 constant BLUE_SPATULA = 11;
  uint8 constant BUCKET_OF_BLUE_PAINT = 12;
  uint8 constant BUCKET_OF_RED_PAINT = 13;
  uint8 constant BURNED_OUT_GRAPHICS_CARD = 14;
  uint8 constant COLD_STORAGE_WALLET = 15;
  uint8 constant DOUBLE_DUMBBELLS = 16;
  uint8 constant FRESH_SALMON = 17;
  uint8 constant HAND_IN_A_BLUE_COOKIE_JAR = 18;
  uint8 constant HAND_IN_A_RED_COOKIE_JAR = 19;
  uint8 constant HOT_WALLET = 20;
  uint8 constant MINERS_PICKAXE = 21;
  uint8 constant NINJA_SWORDS = 22;
  uint8 constant NONE = 23;
  uint8 constant PHISHING_NET = 24;
  uint8 constant PHISHING_ROD = 25;
  uint8 constant PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET = 26;
  uint8 constant PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET = 27;
  uint8 constant PINK_FINGERNAIL_POLISH = 28;
  uint8 constant PINK_PURSE = 29;
  uint8 constant PROOF_OF_RIBEYE_STEAK = 30;
  uint8 constant RED_BALLOON = 31;
  uint8 constant RED_BOXING_GLOVES = 32;
  uint8 constant RED_FINGERNAIL_POLISH = 33;
  uint8 constant RED_GARDENER_TROWEL = 34;
  uint8 constant RED_MERGE_BEARS_FOAM_FINGER = 35;
  uint8 constant RED_PURSE = 36;
  uint8 constant RED_SPATULA = 37;
  uint8 constant TOILET_PAPER = 38;
  uint8 constant WOODEN_WALKING_CANE = 39;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsSpecies {
  uint8 constant BLACK = 1;
  uint8 constant POLAR = 2;
  uint8 constant PANDA = 3;
  uint8 constant REVERSE_PANDA = 4;
  uint8 constant GOLD_PANDA = 5;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../Gene.sol";

library OptionSpecies {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 species = Gene.getGene(TraitDefs.SPECIES, dna);
    // this gene is hard-coded at "mint" or at "merge"
    // 1 is black
    // 2 is polar
    // 3 is panda
    // 4 is reverse panda
    // 5 is gold panda

    if (species == 1) {
      return TraitOptionsSpecies.BLACK;
    } else if (species == 2) {
      return TraitOptionsSpecies.POLAR;
    } else if (species == 3) {
      return TraitOptionsSpecies.PANDA;
    } else if (species == 4) {
      return TraitOptionsSpecies.REVERSE_PANDA;
    } else if (species == 5) {
      return TraitOptionsSpecies.GOLD_PANDA;
    }
    return TraitOptionsSpecies.BLACK;
  }
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