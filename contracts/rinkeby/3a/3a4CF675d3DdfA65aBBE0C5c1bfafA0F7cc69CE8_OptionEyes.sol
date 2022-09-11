// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsEyes.sol";
import "../Gene.sol";

library OptionEyes {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 eyes = Gene.getGene(TraitDefs.EYES, dna);
    uint16 variant = eyes % 20;

    if (variant == 0) {
      return TraitOptionsEyes.ANNOYED_BLUE_EYES;
    } else if (variant == 1) {
      return TraitOptionsEyes.ANNOYED_BROWN_EYES;
    } else if (variant == 2) {
      return TraitOptionsEyes.ANNOYED_GREEN_EYES;
    } else if (variant == 3) {
      return TraitOptionsEyes.BEADY_EYES;
    } else if (variant == 4) {
      return TraitOptionsEyes.BEADY_RED_EYES;
    } else if (variant == 5) {
      return TraitOptionsEyes.BORED_BLUE_EYES;
    } else if (variant == 6) {
      return TraitOptionsEyes.BORED_BROWN_EYES;
    } else if (variant == 7) {
      return TraitOptionsEyes.BORED_GREEN_EYES;
    } else if (variant == 8) {
      return TraitOptionsEyes.DILATED_BLUE_EYES;
    } else if (variant == 9) {
      return TraitOptionsEyes.DILATED_BROWN_EYES;
    } else if (variant == 10) {
      return TraitOptionsEyes.DILATED_GREEN_EYES;
    } else if (variant == 11) {
      return TraitOptionsEyes.NEUTRAL_BLUE_EYES;
    } else if (variant == 12) {
      return TraitOptionsEyes.NEUTRAL_BROWN_EYES;
    } else if (variant == 13) {
      return TraitOptionsEyes.NEUTRAL_GREEN_EYES;
    } else if (variant == 14) {
      return TraitOptionsEyes.SQUARE_BLUE_EYES;
    } else if (variant == 15) {
      return TraitOptionsEyes.SQUARE_BROWN_EYES;
    } else if (variant == 16) {
      return TraitOptionsEyes.SQUARE_GREEN_EYES;
    } else if (variant == 17) {
      return TraitOptionsEyes.SURPRISED_BLUE_EYES;
    } else if (variant == 18) {
      return TraitOptionsEyes.SURPRISED_BROWN_EYES;
    } else if (variant == 19) {
      return TraitOptionsEyes.SURPRISED_GREEN_EYES;
    }
    return TraitOptionsEyes.BORED_BLUE_EYES;
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

library TraitOptionsEyes {
  uint8 constant ANNOYED_BLUE_EYES = 0;
  uint8 constant ANNOYED_BROWN_EYES = 1;
  uint8 constant ANNOYED_GREEN_EYES = 2;
  uint8 constant BEADY_EYES = 3;
  uint8 constant BEADY_RED_EYES = 4;
  uint8 constant BORED_BLUE_EYES = 5;
  uint8 constant BORED_BROWN_EYES = 6;
  uint8 constant BORED_GREEN_EYES = 7;
  uint8 constant DILATED_BLUE_EYES = 8;
  uint8 constant DILATED_BROWN_EYES = 9;
  uint8 constant DILATED_GREEN_EYES = 10;
  uint8 constant NEUTRAL_BLUE_EYES = 11;
  uint8 constant NEUTRAL_BROWN_EYES = 12;
  uint8 constant NEUTRAL_GREEN_EYES = 13;
  uint8 constant SQUARE_BLUE_EYES = 14;
  uint8 constant SQUARE_BROWN_EYES = 15;
  uint8 constant SQUARE_GREEN_EYES = 16;
  uint8 constant SURPRISED_BLUE_EYES = 17;
  uint8 constant SURPRISED_BROWN_EYES = 18;
  uint8 constant SURPRISED_GREEN_EYES = 19;
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