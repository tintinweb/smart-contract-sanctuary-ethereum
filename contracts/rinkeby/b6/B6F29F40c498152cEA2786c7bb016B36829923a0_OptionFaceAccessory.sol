// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsFaceAccessory.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../../lib_constants/trait_options/TraitOptionsLocale.sol";
import "./OptionSpecies.sol";
import "./OptionLocale.sol";
import "../Gene.sol";

library OptionFaceAccessory {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 faceAccessory = Gene.getGene(TraitDefs.FACE_ACCESSORY, dna);
    // uint16 variant = faceAccessory % 24;
    uint16 rarityRoll = faceAccessory % 3575;
    uint8 species = OptionSpecies.getOption(dna);
    uint8 locale = OptionLocale.getOption(dna);

    // 1(2000) + 11(100) + 8(50) + 3(25)
    // 2000 + 1100 + 400 + 75
    // 3575

    if (rarityRoll < 2000) {
      // none
      return TraitOptionsFaceAccessory.NONE;
    } else if (rarityRoll >= 2000 && rarityRoll < 3100) {
      // 100 weight
      uint16 coinFlip = rarityRoll % 2;
      uint16 variant = rarityRoll % 7;

      // if black or panda == 0
      if (species != TraitOptionsSpecies.POLAR && coinFlip == 0) {
        if (variant == 0) {
          return
            TraitOptionsFaceAccessory.BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
        } else if (variant == 1) {
          return TraitOptionsFaceAccessory.BLUE_FRAMED_GLASSES;
        } else if (variant == 2) {
          return TraitOptionsFaceAccessory.BLUE_MEDICAL_MASK;
        } else if (variant == 3) {
          return TraitOptionsFaceAccessory.BLUE_NINJA_MASK;
        } else if (variant == 4) {
          return TraitOptionsFaceAccessory.BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
        } else if (variant == 5) {
          return TraitOptionsFaceAccessory.BLUE_VERBS_GLASSES;
        } else if (variant == 6) {
          return TraitOptionsFaceAccessory.BLUE_AND_BLACK_CHECKERED_BANDANA;
        }
      }
      // if polar or panda
      if (species != TraitOptionsSpecies.BLACK && coinFlip == 1) {
        if (variant == 0) {
          return TraitOptionsFaceAccessory.RED_FRAMED_GLASSES;
        } else if (variant == 1) {
          return TraitOptionsFaceAccessory.RED_MEDICAL_MASK;
        } else if (variant == 2) {
          return TraitOptionsFaceAccessory.RED_NINJA_MASK;
        } else if (variant == 3) {
          return TraitOptionsFaceAccessory.RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
        } else if (variant == 4) {
          return TraitOptionsFaceAccessory.RED_VERBS_GLASSES;
        } else if (variant == 5) {
          return TraitOptionsFaceAccessory.RED_AND_WHITE_CHECKERED_BANDANA;
        } else if (variant == 6) {
          return
            TraitOptionsFaceAccessory.WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
        }
      }
    } else if (rarityRoll >= 3100 && rarityRoll < 3500) {
      uint16 variant = rarityRoll % 4;

      // 50 weight
      if (variant == 0 && locale != TraitOptionsLocale.NORTH_AMERICAN) {
        return TraitOptionsFaceAccessory.BLACK_NINJA_MASK;
      } else if (variant == 1 && locale != TraitOptionsLocale.NORTH_AMERICAN) {
        return TraitOptionsFaceAccessory.WHITE_NINJA_MASK;
      } else if (variant == 2) {
        return TraitOptionsFaceAccessory.CANDY_CANE;
      } else if (variant == 3) {
        return TraitOptionsFaceAccessory.BROWN_FRAMED_GLASSES;
      }
    } else if (rarityRoll >= 3500) {
      uint16 variant = rarityRoll % 4;

      // 25 weight
      if (variant == 0) {
        return TraitOptionsFaceAccessory.GOLD_FRAMED_MONOCLE;
      } else if (variant == 1) {
        return TraitOptionsFaceAccessory.GRAY_BEARD;
      } else if (variant == 2) {
        return TraitOptionsFaceAccessory.HEAD_CONE;
        // } else if (variant == 3) {
        // return TraitOptionsFaceAccessory.CLOWN_FACE_PAINT; // special
      } else if (variant == 3) {
        return TraitOptionsFaceAccessory.DRIPPING_HONEY; // special
      }
    }

    return TraitOptionsFaceAccessory.NONE;
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

library TraitOptionsFaceAccessory {
  uint8 constant BLACK_NINJA_MASK = 0;
  uint8 constant BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL = 1;
  uint8 constant BLUE_FRAMED_GLASSES = 2;
  uint8 constant BLUE_MEDICAL_MASK = 3;
  uint8 constant BLUE_NINJA_MASK = 4;
  uint8 constant BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES = 5;
  uint8 constant BLUE_VERBS_GLASSES = 6;
  uint8 constant BLUE_AND_BLACK_CHECKERED_BANDANA = 7;
  uint8 constant BROWN_FRAMED_GLASSES = 8;
  uint8 constant CANDY_CANE = 9;
  uint8 constant GOLD_FRAMED_MONOCLE = 10;
  uint8 constant GRAY_BEARD = 11;
  uint8 constant NONE = 12;
  uint8 constant RED_FRAMED_GLASSES = 13;
  uint8 constant RED_MEDICAL_MASK = 14;
  uint8 constant RED_NINJA_MASK = 15;
  uint8 constant RED_STRAIGHT_BOTTOM_FRAMED_GLASSES = 16;
  uint8 constant RED_VERBS_GLASSES = 17;
  uint8 constant RED_AND_WHITE_CHECKERED_BANDANA = 18;
  uint8 constant WHITE_NINJA_MASK = 19;
  uint8 constant WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL = 20;
  uint8 constant HEAD_CONE = 21;
  // uint8 constant CLOWN_FACE_PAINT = 22;
  uint8 constant DRIPPING_HONEY = 23;
  // moved from jewelry
  // uint8 constant GOLD_STUD_EARRINGS = 24;
  // uint8 constant SILVER_STUD_EARRINGS = 24;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library Gene {
  function getGene(uint8 traitDef, uint256 dna) internal pure returns (uint16) {
    // type(uint16).max
    // right shift traitDef * 16, then bitwise & with the max 16 bit number
    return uint16((dna >> (traitDef * 16)) & uint256(type(uint16).max));
  }
}