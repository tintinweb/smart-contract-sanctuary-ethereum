// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsFootwear.sol";
import "../Gene.sol";

library OptionFootwear {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 footwear = Gene.getGene(TraitDefs.FOOTWEAR, dna);
    uint16 variant = footwear % 29;

    if (variant == 0) {
      return TraitOptionsFootwear.BLACK_GLADIATOR_SANDALS;
    } else if (variant == 1) {
      return TraitOptionsFootwear.BLACK_SNEAKERS;
    } else if (variant == 2) {
      return TraitOptionsFootwear.BLACK_AND_BLUE_SNEAKERS;
    } else if (variant == 3) {
      return TraitOptionsFootwear.BLACK_AND_WHITE_SNEAKERS;
    } else if (variant == 4) {
      return TraitOptionsFootwear.BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE;
    } else if (variant == 5) {
      return TraitOptionsFootwear.BLUE_CROCS;
    } else if (variant == 6) {
      return TraitOptionsFootwear.BLUE_FLIP_FLOPS;
    } else if (variant == 7) {
      return TraitOptionsFootwear.BLUE_HIGH_HEELS;
    } else if (variant == 8) {
      return TraitOptionsFootwear.BLUE_SNEAKERS;
    } else if (variant == 9) {
      return TraitOptionsFootwear.BLUE_TOENAIL_POLISH;
    } else if (variant == 10) {
      return TraitOptionsFootwear.BLUE_WORK_BOOTS;
    } else if (variant == 11) {
      return TraitOptionsFootwear.BLUE_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (variant == 12) {
      return TraitOptionsFootwear.PINK_HIGH_HEELS;
    } else if (variant == 13) {
      return TraitOptionsFootwear.PINK_TOENAIL_POLISH;
    } else if (variant == 14) {
      return TraitOptionsFootwear.PINK_WORK_BOOTS;
    } else if (variant == 15) {
      return TraitOptionsFootwear.RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE;
    } else if (variant == 16) {
      return TraitOptionsFootwear.RED_CROCS;
    } else if (variant == 17) {
      return TraitOptionsFootwear.RED_FLIP_FLOPS;
    } else if (variant == 18) {
      return TraitOptionsFootwear.RED_HIGH_HEELS;
    } else if (variant == 19) {
      return TraitOptionsFootwear.RED_TOENAIL_POLISH;
    } else if (variant == 20) {
      return TraitOptionsFootwear.RED_WORK_BOOTS;
    } else if (variant == 21) {
      return TraitOptionsFootwear.RED_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (variant == 22) {
      return TraitOptionsFootwear.STEPPED_IN_A_PUMPKIN;
    } else if (variant == 23) {
      return TraitOptionsFootwear.TAN_COWBOY_BOOTS;
    } else if (variant == 24) {
      return TraitOptionsFootwear.TAN_WORK_BOOTS;
    } else if (variant == 25) {
      return TraitOptionsFootwear.WATERMELON_SHOES;
    } else if (variant == 26) {
      return TraitOptionsFootwear.WHITE_SNEAKERS;
    } else if (variant == 27) {
      return TraitOptionsFootwear.WHITE_AND_RED_SNEAKERS;
    } else if (variant == 28) {
      return TraitOptionsFootwear.YELLOW_RAIN_BOOTS;
    }
    return TraitOptionsFootwear.BLACK_SNEAKERS;
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

library TraitOptionsFootwear {
  uint8 constant BLACK_GLADIATOR_SANDALS = 0;
  uint8 constant BLACK_SNEAKERS = 1;
  uint8 constant BLACK_AND_BLUE_SNEAKERS = 2;
  uint8 constant BLACK_AND_WHITE_SNEAKERS = 3;
  uint8 constant BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE = 4;
  uint8 constant BLUE_CROCS = 5;
  uint8 constant BLUE_FLIP_FLOPS = 6;
  uint8 constant BLUE_HIGH_HEELS = 7;
  uint8 constant BLUE_SNEAKERS = 8;
  uint8 constant BLUE_TOENAIL_POLISH = 9;
  uint8 constant BLUE_WORK_BOOTS = 10;
  uint8 constant BLUE_AND_GRAY_BASKETBALL_SNEAKERS = 11;
  uint8 constant PINK_HIGH_HEELS = 12;
  uint8 constant PINK_TOENAIL_POLISH = 13;
  uint8 constant PINK_WORK_BOOTS = 14;
  uint8 constant RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE = 15;
  uint8 constant RED_CROCS = 16;
  uint8 constant RED_FLIP_FLOPS = 17;
  uint8 constant RED_HIGH_HEELS = 18;
  uint8 constant RED_TOENAIL_POLISH = 19;
  uint8 constant RED_WORK_BOOTS = 20;
  uint8 constant RED_AND_GRAY_BASKETBALL_SNEAKERS = 21;
  uint8 constant STEPPED_IN_A_PUMPKIN = 22;
  uint8 constant TAN_COWBOY_BOOTS = 23;
  uint8 constant TAN_WORK_BOOTS = 24;
  uint8 constant WATERMELON_SHOES = 25;
  uint8 constant WHITE_SNEAKERS = 26;
  uint8 constant WHITE_AND_RED_SNEAKERS = 27;
  uint8 constant YELLOW_RAIN_BOOTS = 28;
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