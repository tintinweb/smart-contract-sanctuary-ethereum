// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Nose {
  using Strings for uint256;
  string constant NOSE_NOSE___BLACK_NOSTRILS_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOUlEQVR42uzRwQkAMAwDMWf/pVu6gqGf6AYQGGfKAgAAAH+AvBrgEpNqQuJGAAAAAAAAAMBO4AgwAI81D/VRpyjKAAAAAElFTkSuQmCC";

  string constant NOSE_NOSE___BLACK_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAANUlEQVR42uzRwQkAMAwDsev+Szc75FWqG0AY3FkWAAAAvAI07RaUFwAAAAAAAAAAfwJXgAEA1IYP+9jVtBMAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___BLUE_NOSTRILS_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFQFbNOk65////QZQLLAAAAAN0Uk5T//8A18oNQQAAADlJREFUeNrs0UEKACAQAkDr/48u+oKwl0Y8D4jZZQIAAAAzQF4aYOW2mpC4EQAAAAAAAADwJ3AEGAD3kR/nhgLxZAAAAABJRU5ErkJggg==";

  string constant NOSE_NOSE___PINK_NOSTRILS_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6Jr/yqLV////hVu2pwAAAAN0Uk5T//8A18oNQQAAADlJREFUeNrs0UEKACAQAkDr/48u+oKwl0Y8D4jZZQIAAAAzQF4aYOW2mpC4EQAAAAAAAADwJ3AEGAD3kR/nhgLxZAAAAABJRU5ErkJggg==";

  string constant NOSE_NOSE___RUNNY_BLACK_NOSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAUf9a////Kts8ygAAAAN0Uk5T//8A18oNQQAAADpJREFUeNrs0sEJADAMAzGn+w9dyAqBhoJuAD2Mc4YFAAAA3gDpNoEWarpB+QEAAAAAAAAA4EPgCjAAnvkf31y6WrwAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___SMALL_BLUE_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFQFbN////mfWZAQAAAAJ0Uk5T/wDltzBKAAAANUlEQVR42uzRwQkAMAwDsev+Szc75FWqG0AY3FkWAAAAvAI07RaUFwAAAAAAAAAAfwJXgAEA1IYP+9jVtBMAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___SMALL_PINK_NOSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6Jr/////Gn0/cgAAAAJ0Uk5T/wDltzBKAAAANUlEQVR42uzRwQkAMAwDsev+Szc75FWqG0AY3FkWAAAAvAI07RaUFwAAAAAAAAAAfwJXgAEA1IYP+9jVtBMAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___WIDE_BLACK_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzRsQkAMAwDQXn/pQNZIIUhBnPf6xqlmgUAAAD+ALlNAvXcuxEAAAAAAAAAsBU4AgwAYoUP8bYcFD0AAAAASUVORK5CYII=";

  string constant NOSE_NOSE___WIDE_BLUE_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFQFbNOk65////QZQLLAAAAAN0Uk5T//8A18oNQQAAADxJREFUeNrs0bEJACAQA8Do/kMrLmARsJALqY9/klkmAAAA8AbISQOM7DYvXA8wIwAAAAAAAADgV2AJMADLYx/j6hglmQAAAABJRU5ErkJggg==";

  string constant NOSE_NOSE___WIDE_PINK_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6Jr/yqLV////hVu2pwAAAAN0Uk5T//8A18oNQQAAADxJREFUeNrs0bEJACAQA8Do/kMrLmARsJALqY9/klkmAAAA8AbISQOM7DYvXA8wIwAAAAAAAADgV2AJMADLYx/j6hglmQAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return NOSE_NOSE___BLACK_NOSTRILS_SNIFFER;
    } else if (assetNum == 1) {
      return NOSE_NOSE___BLACK_SNIFFER;
    } else if (assetNum == 2) {
      return NOSE_NOSE___BLUE_NOSTRILS_SNIFFER;
    } else if (assetNum == 3) {
      return NOSE_NOSE___PINK_NOSTRILS_SNIFFER;
    } else if (assetNum == 4) {
      return NOSE_NOSE___RUNNY_BLACK_NOSE;
    } else if (assetNum == 5) {
      return NOSE_NOSE___SMALL_BLUE_SNIFFER;
    } else if (assetNum == 6) {
      return NOSE_NOSE___SMALL_PINK_NOSE;
    } else if (assetNum == 7) {
      return NOSE_NOSE___WIDE_BLACK_SNIFFER;
    } else if (assetNum == 8) {
      return NOSE_NOSE___WIDE_BLUE_SNIFFER;
    } else if (assetNum == 9) {
      return NOSE_NOSE___WIDE_PINK_SNIFFER;
    }
    return NOSE_NOSE___BLACK_NOSTRILS_SNIFFER;
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