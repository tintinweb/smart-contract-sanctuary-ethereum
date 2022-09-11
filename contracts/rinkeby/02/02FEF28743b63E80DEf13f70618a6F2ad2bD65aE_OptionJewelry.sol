// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsJewelry.sol";
import "../Gene.sol";

library OptionJewelry {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 jewelry = Gene.getGene(TraitDefs.JEWELRY, dna);
    uint16 variant = jewelry % 18;

    if (variant == 0) {
      return TraitOptionsJewelry.BLUE_BRACELET;
    } else if (variant == 1) {
      return TraitOptionsJewelry.BLUE_SPORTS_WATCH;
    } else if (variant == 2) {
      return
        TraitOptionsJewelry.DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION;
    } else if (variant == 3) {
      return TraitOptionsJewelry.DOUBLE_GOLD_CHAINS;
    } else if (variant == 4) {
      return TraitOptionsJewelry.DOUBLE_SILVER_CHAINS;
    } else if (variant == 5) {
      return TraitOptionsJewelry.GOLD_CHAIN_WITH_MEDALLION;
    } else if (variant == 6) {
      return TraitOptionsJewelry.GOLD_CHAIN_WITH_RED_RUBY;
    } else if (variant == 7) {
      return TraitOptionsJewelry.GOLD_CHAIN;
    } else if (variant == 8) {
      return TraitOptionsJewelry.GOLD_STUD_EARRINGS;
    } else if (variant == 9) {
      return TraitOptionsJewelry.GOLD_WATCH_ON_LEFT_WRIST;
    } else if (variant == 10) {
      return TraitOptionsJewelry.LEFT_HAND_GOLD_RINGS;
    } else if (variant == 11) {
      return TraitOptionsJewelry.LEFT_HAND_SILVER_RINGS;
    } else if (variant == 12) {
      return TraitOptionsJewelry.RED_BRACELET;
    } else if (variant == 13) {
      return TraitOptionsJewelry.RED_SPORTS_WATCH;
    } else if (variant == 14) {
      return TraitOptionsJewelry.SILVER_CHAIN_WITH_MEDALLION;
    } else if (variant == 15) {
      return TraitOptionsJewelry.SILVER_CHAIN_WITH_RED_RUBY;
    } else if (variant == 16) {
      return TraitOptionsJewelry.SILVER_CHAIN;
    } else if (variant == 17) {
      return TraitOptionsJewelry.SILVER_STUD_EARRINGS;
    }

    return TraitOptionsJewelry.GOLD_CHAIN;
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

library TraitOptionsJewelry {
  uint8 constant BLUE_BRACELET = 0;
  uint8 constant BLUE_SPORTS_WATCH = 1;
  uint8 constant DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION = 2;
  uint8 constant DOUBLE_GOLD_CHAINS = 3;
  uint8 constant DOUBLE_SILVER_CHAINS = 4;
  uint8 constant GOLD_CHAIN_WITH_MEDALLION = 5;
  uint8 constant GOLD_CHAIN_WITH_RED_RUBY = 6;
  uint8 constant GOLD_CHAIN = 7;
  uint8 constant GOLD_STUD_EARRINGS = 8;
  uint8 constant GOLD_WATCH_ON_LEFT_WRIST = 9;
  uint8 constant LEFT_HAND_GOLD_RINGS = 10;
  uint8 constant LEFT_HAND_SILVER_RINGS = 11;
  uint8 constant RED_BRACELET = 12;
  uint8 constant RED_SPORTS_WATCH = 13;
  uint8 constant SILVER_CHAIN_WITH_MEDALLION = 14;
  uint8 constant SILVER_CHAIN_WITH_RED_RUBY = 15;
  uint8 constant SILVER_CHAIN = 16;
  uint8 constant SILVER_STUD_EARRINGS = 17;
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