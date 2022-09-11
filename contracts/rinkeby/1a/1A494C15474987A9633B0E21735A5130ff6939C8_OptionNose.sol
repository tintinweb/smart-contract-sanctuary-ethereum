// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsNose.sol";
import "../Gene.sol";

library OptionNose {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 nose = Gene.getGene(TraitDefs.NOSE, dna);
    uint16 variant = nose % 10;

    if (variant == 0) {
      return TraitOptionsNose.BLACK_NOSTRILS_SNIFFER;
    } else if (variant == 1) {
      return TraitOptionsNose.BLACK_SNIFFER;
    } else if (variant == 2) {
      return TraitOptionsNose.BLUE_NOSTRILS_SNIFFER;
    } else if (variant == 3) {
      return TraitOptionsNose.PINK_NOSTRILS_SNIFFER;
    } else if (variant == 4) {
      return TraitOptionsNose.RUNNY_BLACK_NOSE;
    } else if (variant == 5) {
      return TraitOptionsNose.SMALL_BLUE_SNIFFER;
    } else if (variant == 6) {
      return TraitOptionsNose.SMALL_PINK_NOSE;
    } else if (variant == 7) {
      return TraitOptionsNose.WIDE_BLACK_SNIFFER;
    } else if (variant == 8) {
      return TraitOptionsNose.WIDE_BLUE_SNIFFER;
    } else if (variant == 9) {
      return TraitOptionsNose.WIDE_PINK_SNIFFER;
    }
    return TraitOptionsNose.BLACK_NOSTRILS_SNIFFER;
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

library TraitOptionsNose {
  uint8 constant BLACK_NOSTRILS_SNIFFER = 0;
  uint8 constant BLACK_SNIFFER = 1;
  uint8 constant BLUE_NOSTRILS_SNIFFER = 2;
  uint8 constant PINK_NOSTRILS_SNIFFER = 3;
  uint8 constant RUNNY_BLACK_NOSE = 4;
  uint8 constant SMALL_BLUE_SNIFFER = 5;
  uint8 constant SMALL_PINK_NOSE = 6;
  uint8 constant WIDE_BLACK_SNIFFER = 7;
  uint8 constant WIDE_BLUE_SNIFFER = 8;
  uint8 constant WIDE_PINK_SNIFFER = 9;
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