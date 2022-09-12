// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Belly {
  using Strings for uint256;
  string constant BELLY_BELLY___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/+2o+dZOAAAA8uGf//jb////NLhWdwAAAAZ0Uk5T//////8As7+kvwAAAKRJREFUeNrs1UsOgCAMBNCxrfe/solCRKHqQHRjZz+PT0LBPBgEEEAAAQTwE0CKdAAiUxGf8IBDfSU4YOub3Qu46j/ZA54doBcwK05BADKdrsB8AZdXgDVZYIFUTwQP5LJZJjhgXx5ZoACgFhgAaAg0YP3AqZ8yCigLYADQVp8AmoJSr/EFQCmgFry+P1RVD3UVfqxrEX6sj38s8TsHEMDHwCLAACSDRysbj8dQAAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___LARGE_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF2dnZ6+vrNTU1AAAA09PT////FNnvdQAAAAZ0Uk5T//////8As7+kvwAAAJRJREFUeNrs1dEKgCAMheHZ1vu/ciAamzXpJArRzv3/4UUp7YOjAAIIIIAAfgKw2guAeVPzCQ8weSYw4NK7Aj3tPWEukMpggE1+EgwBuaO8SiBAUn0REgLYvgooQNQIqwGiVvg+ICsBuQEEAK6Ce4CpgP2UBQIaodP7l6qI+p3F7XvXuqjh1/r4wxKvcwABLAYOAQYAmr1IGcCKtUIAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___LARGE_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vr4ODgAAAA09PT////omcZtAAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVwQ7AIAgDULD7/29eshM4IaKZl7X3vnixyLUZIUCAAAECPwGayQLQmpjERAS4+kPUgFc/FGS2HwkfA/qkDvh+LmSAqheqgGonnAZUe4HAPoCTAAYACsBAiB4wC8gK4D8TSkAnJP14VAEzKAj72azDpD7r+4eF15kAgcPALcAA+cg5Kmqq9loAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___LARGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1RUVFAAAALS0t////IsSZNwAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVwQ7AIAgDULD7/29eshM4IaKZl7X3vnixyLUZIUCAAAECPwGayQLQmpjERAS4+kPUgFc/FGS2HwkfA/qkDvh+LmSAqheqgGonnAZUe4HAPoCTAAYACsBAiB4wC8gK4D8TSkAnJP14VAEzKAj72azDpD7r+4eF15kAgcPALcAA+cg5Kmqq9loAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___REVERSE_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU12dnZ6+vrAAAALS0t////gYpa6wAAAAZ0Uk5T//////8As7+kvwAAAJhJREFUeNrs1UsOgDAIBFAUvP+VTfoLRGkcmzYxMvt57aIFOgZDAQQQQAAB/ARglRcA867iEx5g6onAgEvfFehp3xPmAlQCA2zqjWAISL38CCqBAPlc3lK43AIATL8JKND6VVgNqH4Rvg/ISkBuAAGAi+BfYCpgn7JAgBV6fX+oiqjvLG6/N9ZFBR/r44sltnMAASwGTgEGAPSqSIkvuflUAAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___SMALL_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU12dnZ6+vrAAAALS0t////gYpa6wAAAAZ0Uk5T//////8As7+kvwAAAKFJREFUeNrs1UsOgCAMBFAs9f5X9oemVYc4EtnY2c9LILSksTEpgAACCCCAnwDZ5AWQczLBBAJcfSU44NKHQnraR8LHgKzhAd+vCzVAxAsssDSHOYdAAqVeCB4w/V3oC7h+EboCcgWkGdCegN7cgRLALNwA1DSqnN8BC7hbEHwCuNI24Rgm2MdLVdWMs8J+ba2rCb/W2z+W+J0DCKAzMAkwAHmJSDOoQJz8AAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___SMALL_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vr4ODgAAAA09PT////omcZtAAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVSwrAIBAD0BnT+5+54KJYNaWjIJYm+7zVfOyYjAkQIECAgJ8AqcgAkJIV4QQDbvVMxICmTwV722fCpkC3T4TdAc8ZBvzKGOBeCUHAvRa+D2AlgA6AAJCFBghtI9o5mAUQAmqB9/lRBYplAu0/nXUUiZ/1+cei7yxAwGLgFGAAl2w4/zBwQbEAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1RUVFAAAALS0t////IsSZNwAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVSwrAIBAD0BnT+5+54KJYNaWjIJYm+7zVfOyYjAkQIECAgJ8AqcgAkJIV4QQDbvVMxICmTwV722fCpkC3T4TdAc8ZBvzKGOBeCUHAvRa+D2AlgA6AAJCFBghtI9o5mAUQAmqB9/lRBYplAu0/nXUUiZ/1+cei7yxAwGLgFGAAl2w4/zBwQbEAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return BELLY_BELLY___GOLD_PANDA;
    } else if (assetNum == 1) {
      return BELLY_BELLY___LARGE_PANDA;
    } else if (assetNum == 2) {
      return BELLY_BELLY___LARGE_POLAR;
    } else if (assetNum == 3) {
      return BELLY_BELLY___LARGE;
    } else if (assetNum == 4) {
      return BELLY_BELLY___REVERSE_PANDA;
    } else if (assetNum == 5) {
      return BELLY_BELLY___SMALL_PANDA;
    } else if (assetNum == 6) {
      return BELLY_BELLY___SMALL_POLAR;
    } else if (assetNum == 7) {
      return BELLY_BELLY___SMALL;
    }
    return BELLY_BELLY___GOLD_PANDA;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}