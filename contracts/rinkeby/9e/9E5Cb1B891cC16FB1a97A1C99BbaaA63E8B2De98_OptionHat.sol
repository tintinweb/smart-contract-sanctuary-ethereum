// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsHat.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../../lib_constants/trait_options/TraitOptionsLocale.sol";
import "../Gene.sol";
import "./OptionSpecies.sol";
import "./OptionLocale.sol";

library OptionHat {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 hat = Gene.getGene(TraitDefs.HAT, dna);
    // uint16 variant = hat % 39;

    uint8 species = OptionSpecies.getOption(dna);
    uint8 locale = OptionLocale.getOption(dna);

    // 1(1000), 21(100), 6(50), 7(25), 5(10), 3(5)
    // 1000   , 2100,  300,  175, 50, 15
    // 3640

    uint16 rarityRoll = hat % 3640;

    if (rarityRoll < 1000) {
      // return none
      return TraitOptionsHat.NONE;
    } else if (rarityRoll >= 1000 && rarityRoll < 3100) {
      // return a weight 100 option

      uint16 variant = rarityRoll % 14;

      if (species != TraitOptionsSpecies.POLAR && rarityRoll % 2 == 0) {
        // BLUES
        if (variant == 0) {
          return TraitOptionsHat.BLACK_WITH_BLUE_HEADPHONES;
        } else if (variant == 1) {
          return TraitOptionsHat.BLACK_WITH_BLUE_TOP_HAT;
        } else if (variant == 2) {
          return TraitOptionsHat.BLUE_BASEBALL_CAP;
        } else if (variant == 3) {
          return TraitOptionsHat.TINY_BLUE_HAT;
        } else if (variant == 4) {
          return TraitOptionsHat.SHIRT_BLACK_AND_BLUE_BASEBALL_CAP;
        }
      }

      if (species != TraitOptionsSpecies.BLACK && rarityRoll % 2 == 1) {
        // REDS
        if (variant == 0) {
          return TraitOptionsHat.RED_BASEBALL_CAP;
        } else if (variant == 1) {
          return TraitOptionsHat.RED_SHOWER_CAP;
        } else if (variant == 2) {
          return TraitOptionsHat.TINY_RED_HAT;
        } else if (variant == 3) {
          return TraitOptionsHat.WHITE_AND_RED_BASEBALL_CAP;
        } else if (variant == 4) {
          return TraitOptionsHat.WHITE_WITH_RED_HEADPHONES;
        } else if (variant == 5) {
          return TraitOptionsHat.WHITE_WITH_RED_TOP_HAT;
        } else if (variant == 6) {
          return TraitOptionsHat.SHIRT_RED_UMBRELLA_HAT;
        }
      }

      if (variant == 7) {
        return TraitOptionsHat.BLACK_BOWLER_HAT;
      } else if (variant == 8) {
        return TraitOptionsHat.BLACK_TOP_HAT;
      } else if (variant == 9 && locale != TraitOptionsLocale.ASIAN) {
        return TraitOptionsHat.PINK_SUNHAT;
      } else if (variant == 10) {
        return TraitOptionsHat.TAN_COWBOY_HAT;
      } else if (variant == 11 && locale != TraitOptionsLocale.ASIAN) {
        return TraitOptionsHat.TAN_SUNHAT;
      } else if (variant == 12) {
        return TraitOptionsHat.WHITE_BOWLER_HAT;
      } else if (variant == 13) {
        return TraitOptionsHat.WHITE_TOP_HAT;
      }
    } else if (rarityRoll >= 3100 && rarityRoll < 3400) {
      // return a weight 50 option

      if (species == TraitOptionsSpecies.BLACK) {
        return TraitOptionsHat.GRADUATION_CAP_WITH_BLUE_TASSEL;
      } else if (species == TraitOptionsSpecies.POLAR) {
        return TraitOptionsHat.GRADUATION_CAP_WITH_RED_TASSEL;
      } else {
        if (rarityRoll % 2 == 0) {
          return TraitOptionsHat.RED_DEFI_WIZARD_HAT;
        } else {
          return TraitOptionsHat.RED_SPORTS_HELMET;
        }
      }
    } else if (rarityRoll >= 3400 && rarityRoll < 3575) {
      // return weight 25
      uint16 variant = rarityRoll % 4;
      if (
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        variant = rarityRoll % 5;
      }

      if (variant == 0) {
        return TraitOptionsHat.BLACK_AND_WHITE_STRIPED_JAIL_CAP;
      } else if (variant == 1) {
        if (species == TraitOptionsSpecies.BLACK) {
          return TraitOptionsHat.BLUE_UMBRELLA_HAT;
        } else if (species == TraitOptionsSpecies.POLAR) {
          return TraitOptionsHat.RED_UMBRELLA_HAT;
        } else {
          // is a panda
          if (rarityRoll % 2 == 0) {
            return TraitOptionsHat.BLUE_UMBRELLA_HAT;
          } else {
            return TraitOptionsHat.RED_UMBRELLA_HAT;
          }
        }
      } else if (variant == 2) {
        return TraitOptionsHat.PINK_BUTTERFLY;
      }
      if (variant == 3) {
        if (species == TraitOptionsSpecies.BLACK) {
          return TraitOptionsHat.ASTRONAUT_HELMET; // Blue
        } else if (species == TraitOptionsSpecies.POLAR) {
          return TraitOptionsHat.RED_ASTRONAUT_HELMET;
        } else {
          // is a panda
          if (rarityRoll % 2 == 0) {
            return TraitOptionsHat.ASTRONAUT_HELMET;
          } else {
            return TraitOptionsHat.RED_ASTRONAUT_HELMET;
          }
        }
      } else if (variant == 4) {
        return TraitOptionsHat.NODE_OPERATORS_YELLOW_HARDHAT;
      }
    } else if (rarityRoll >= 3575 && rarityRoll < 3625) {
      // return weight 10
      uint16 variant = rarityRoll % 3;
      if (
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        variant = rarityRoll % 5;
      }

      if (variant == 0) {
        return TraitOptionsHat.CHERRY_ON_TOP;
      } else if (variant == 1) {
        return TraitOptionsHat.GREEN_GOO;
      } else if (variant == 2) {
        return TraitOptionsHat.POLICE_CAP;
      } else if (variant == 3) {
        // !B!W
        return TraitOptionsHat.CRYPTO_INFLUENCER_BLUEBIRD;
      } else if (variant == 4) {
        // !B!W
        return TraitOptionsHat.BULB_HELMET;
      }
    } else {
      // return a weight 5 option
      if (
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        uint16 variant = rarityRoll % 3;
        if (variant == 0) {
          return TraitOptionsHat.GIANT_SUNFLOWER;
        } else if (variant == 1) {
          return TraitOptionsHat.GOLD_CHALICE;
        } else if (variant == 2) {
          return TraitOptionsHat.BAG_OF_ETHEREUM;
        }
        return TraitOptionsHat.BAG_OF_ETHEREUM;
      }
    }

    return TraitOptionsHat.NONE;
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

library TraitOptionsHat {
  uint8 constant ASTRONAUT_HELMET = 0;
  uint8 constant BAG_OF_ETHEREUM = 1;
  uint8 constant BLACK_BOWLER_HAT = 2;
  uint8 constant BLACK_TOP_HAT = 3;
  uint8 constant BLACK_AND_WHITE_STRIPED_JAIL_CAP = 4;
  uint8 constant BLACK_WITH_BLUE_HEADPHONES = 5;
  uint8 constant BLACK_WITH_BLUE_TOP_HAT = 6;
  uint8 constant BLUE_BASEBALL_CAP = 7;
  uint8 constant BLUE_UMBRELLA_HAT = 8;
  uint8 constant BULB_HELMET = 9;
  uint8 constant CHERRY_ON_TOP = 10;
  uint8 constant CRYPTO_INFLUENCER_BLUEBIRD = 11;
  uint8 constant GIANT_SUNFLOWER = 12;
  uint8 constant GOLD_CHALICE = 13;
  uint8 constant GRADUATION_CAP_WITH_BLUE_TASSEL = 14;
  uint8 constant GRADUATION_CAP_WITH_RED_TASSEL = 15;
  uint8 constant GREEN_GOO = 16;
  uint8 constant NODE_OPERATORS_YELLOW_HARDHAT = 17;
  uint8 constant NONE = 18;
  uint8 constant PINK_BUTTERFLY = 19;
  uint8 constant PINK_SUNHAT = 20;
  uint8 constant POLICE_CAP = 21;
  uint8 constant RED_ASTRONAUT_HELMET = 22;
  uint8 constant RED_BASEBALL_CAP = 23;
  uint8 constant RED_DEFI_WIZARD_HAT = 24;
  uint8 constant RED_SHOWER_CAP = 25;
  uint8 constant RED_SPORTS_HELMET = 26;
  uint8 constant RED_UMBRELLA_HAT = 27;
  uint8 constant TAN_COWBOY_HAT = 28;
  uint8 constant TAN_SUNHAT = 29;
  uint8 constant TINY_BLUE_HAT = 30;
  uint8 constant TINY_RED_HAT = 31;
  uint8 constant WHITE_BOWLER_HAT = 32;
  uint8 constant WHITE_TOP_HAT = 33;
  uint8 constant WHITE_AND_RED_BASEBALL_CAP = 34;
  uint8 constant WHITE_WITH_RED_HEADPHONES = 35;
  uint8 constant WHITE_WITH_RED_TOP_HAT = 36;
  uint8 constant SHIRT_BLACK_AND_BLUE_BASEBALL_CAP = 37;
  uint8 constant SHIRT_RED_UMBRELLA_HAT = 38;
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
pragma solidity ^0.8.9;

library TraitOptionsLocale {
  uint8 constant NORTH_AMERICAN = 0;
  uint8 constant SOUTH_AMERICAN = 1;
  uint8 constant ASIAN = 2;
  uint8 constant EUROPEAN = 3;
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

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsLocale.sol";
import "../Gene.sol";

library OptionLocale {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 locale = Gene.getGene(TraitDefs.LOCALE, dna);
    uint16 variant = locale % 4;

    if (variant == 0) {
      return TraitOptionsLocale.NORTH_AMERICAN;
    } else if (variant == 1) {
      return TraitOptionsLocale.SOUTH_AMERICAN;
    } else if (variant == 2) {
      return TraitOptionsLocale.ASIAN;
    } else if (variant == 3) {
      return TraitOptionsLocale.EUROPEAN;
    }
    return TraitOptionsLocale.NORTH_AMERICAN;
  }
}