// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Feet {
  using Strings for uint256;
  string constant FEET_FEET___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF+dZOAAAA7MtK//jb1bY+8vLy8uvQ////Czaq5AAAAAh0Uk5T/////////wDeg71ZAAAAn0lEQVR42uzU0Q6CMAwF0Hvbov//x66AwBQMlcQHc5s9NEt6Nkoz3C8GBAgQIECAAAECBAgQ8FNgsNcdGyoArUVX3oIVALDVsClqgAMjwrzMnFZ68BTYpd8CY14G1lN5HUihBkz1HYBboYl0bPs2c86zQKuPdyD2hV0A4bkWwOCRi4VP2NQvAs/3ABbd5LVxjINRPPgLGR83/ulFeggwAFg0aqXdA+GjAAAAAElFTkSuQmCC";

  string constant FEET_FEET___SMALL_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAAyMjI2dnZ////Kx1DFwAAAAV0Uk5T/////wD7tg5TAAAAjUlEQVR42uzU2wqAIAwG4B16/2eupVkjD43AIP5d6WgfTke0vAwCAAAAAAAAAAAAAADAVEBknOkBLOILbM8RgEhOQ1IEAQurssPkZeQODoHdcj6QivgLwB273wMN68uW+CmwFegd0LpQB3T/vgBCKcOBFvTadBY4cAeibvK2cdTGKDZewaKb+NMfaRVgALO8PRmJ8eR8AAAAAElFTkSuQmCC";

  string constant FEET_FEET___SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNTU1AAAALS0t////vgF0DAAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NRZCsAgDATQZLz/nduQVgl1pWChTL6MMA83lPSyhAABAgQIECBAgAABAlsBYDzTAxSIAet1BRBBMeC1CFhZyhZzDVfO4BY0DPcDHtIvgLDs/h5kmM+t6CxwBvQJaF2oA05kAB6fBlLMF2HhDKDh5VnXeIqNW7DqTvzpRzoEGADxri3xIUc9nwAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return FEET_FEET___GOLD_PANDA;
    } else if (assetNum == 1) {
      return FEET_FEET___SMALL_PANDA; // polar / reverse_panda
    } else if (assetNum == 2) {
      return FEET_FEET___SMALL; // black / panda
    }
    return FEET_FEET___SMALL;
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