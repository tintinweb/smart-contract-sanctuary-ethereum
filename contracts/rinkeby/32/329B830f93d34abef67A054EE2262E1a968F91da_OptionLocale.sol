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