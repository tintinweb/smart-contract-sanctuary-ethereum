// SPDX-License-Identifier: MIT
// Author: @mschead2
pragma solidity ^0.8.12;

library SharedStructs {
  // enums
  enum StickerTypeEn {
    NONE,
    REGULAR,
    RARE,
    SUPER_RARE,
    ULTRA_RARE
  }

  enum StickerTrade {
    NONE,
    NOT_TRADED,
    TRADED
  }
}

// SPDX-License-Identifier: MIT
// Author: @mschead2
pragma solidity ^0.8.12;

import {SharedStructs as s} from "./SharedStructs.sol";

contract TokenURIPicker {
  string[] private s_regularTokenUris;
  string[] private s_rareTokenUris;
  string[] private s_superRareTokenUris;
  string[] private s_ultraRareTokenUris;

  constructor(
    string[] memory regularTokenUris,
    string[] memory rareTokenUris,
    string[] memory superRareTokenUris,
    string[] memory ultraRareTokenUris
  ) {
    s_regularTokenUris = regularTokenUris;
    s_rareTokenUris = rareTokenUris;
    s_superRareTokenUris = superRareTokenUris;
    s_ultraRareTokenUris = ultraRareTokenUris;
  }

  function calculateChance(uint256 number) external pure returns (s.StickerTypeEn) {
    // return s.StickerTypeEn.REGULAR;
    uint256 n = number % 100;
    if (n <= 79) {
      return s.StickerTypeEn.REGULAR;
    }

    if (n <= 94) {
      return s.StickerTypeEn.RARE;
    }

    return s.StickerTypeEn.SUPER_RARE;
  }

  function getTokenURI(
    s.StickerTypeEn stickerType,
    uint256 stickerTypePictureRandomNumber
  ) external view returns (string memory) {
    if (stickerType == s.StickerTypeEn.ULTRA_RARE) {
      return s_ultraRareTokenUris[stickerTypePictureRandomNumber % s_ultraRareTokenUris.length];
    }

    if (stickerType == s.StickerTypeEn.SUPER_RARE) {
      return s_superRareTokenUris[stickerTypePictureRandomNumber % s_superRareTokenUris.length];
    }

    if (stickerType == s.StickerTypeEn.RARE) {
      return s_rareTokenUris[stickerTypePictureRandomNumber % s_rareTokenUris.length];
    }

    return s_regularTokenUris[stickerTypePictureRandomNumber % s_regularTokenUris.length];
  }
}