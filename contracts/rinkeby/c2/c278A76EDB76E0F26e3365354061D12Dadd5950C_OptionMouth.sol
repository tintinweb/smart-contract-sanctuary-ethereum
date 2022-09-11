// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsMouth.sol";
import "../Gene.sol";

library OptionMouth {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 mouth = Gene.getGene(TraitDefs.MOUTH, dna);
    uint16 variant = mouth % 18;

    if (variant == 0) {
      return TraitOptionsMouth.ANXIOUS;
    } else if (variant == 1) {
      return TraitOptionsMouth.BABY_TOOTH_SMILE;
    } else if (variant == 2) {
      return TraitOptionsMouth.BLUE_LIPSTICK;
    } else if (variant == 3) {
      return TraitOptionsMouth.FULL_MOUTH;
    } else if (variant == 4) {
      return TraitOptionsMouth.MISSING_BOTTOM_TOOTH;
    } else if (variant == 5) {
      return TraitOptionsMouth.NERVOUS_MOUTH;
    } else if (variant == 6) {
      return TraitOptionsMouth.OPEN_MOUTH;
    } else if (variant == 7) {
      return TraitOptionsMouth.PINK_LIPSTICK;
    } else if (variant == 8) {
      return TraitOptionsMouth.RED_LIPSTICK;
    } else if (variant == 9) {
      return TraitOptionsMouth.SAD_FROWN;
    } else if (variant == 10) {
      return TraitOptionsMouth.SMILE_WITH_BUCK_TEETH;
    } else if (variant == 11) {
      return TraitOptionsMouth.SMILE_WITH_PIPE;
    } else if (variant == 12) {
      return TraitOptionsMouth.SMILE;
    } else if (variant == 13) {
      return TraitOptionsMouth.SMIRK;
    } else if (variant == 14) {
      return TraitOptionsMouth.TINY_FROWN;
    } else if (variant == 15) {
      return TraitOptionsMouth.TINY_SMILE;
    } else if (variant == 16) {
      return TraitOptionsMouth.TONGUE_OUT;
    } else if (variant == 17) {
      return TraitOptionsMouth.TOOTHY_SMILE;
    }
    return TraitOptionsMouth.SMILE;
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

library TraitOptionsMouth {
  uint8 constant ANXIOUS = 0;
  uint8 constant BABY_TOOTH_SMILE = 1;
  uint8 constant BLUE_LIPSTICK = 2;
  uint8 constant FULL_MOUTH = 3;
  uint8 constant MISSING_BOTTOM_TOOTH = 4;
  uint8 constant NERVOUS_MOUTH = 5;
  uint8 constant OPEN_MOUTH = 6;
  uint8 constant PINK_LIPSTICK = 7;
  uint8 constant RED_LIPSTICK = 8;
  uint8 constant SAD_FROWN = 9;
  uint8 constant SMILE_WITH_BUCK_TEETH = 10;
  uint8 constant SMILE_WITH_PIPE = 11;
  uint8 constant SMILE = 12;
  uint8 constant SMIRK = 13;
  uint8 constant TINY_FROWN = 14;
  uint8 constant TINY_SMILE = 15;
  uint8 constant TONGUE_OUT = 16;
  uint8 constant TOOTHY_SMILE = 17;
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