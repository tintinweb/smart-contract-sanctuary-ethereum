// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Arms {
  using Strings for uint256;

  string constant ARMS_ARMS___AVERAGE_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA2dnZ////Lc7C2wAAAAR0Uk5T////AEAqqfQAAACJSURBVHja7NXBCoAwDAPQJv7/Pyuo4Fw6KqIHzW5t6aM7dIvp5gkDBgwYMPALAEASlAAg4lBagoyItP0EZIQC1vamsmZQA7Z+ASjhAWDvV4AQojTAYIQUYJvle8B+Aw30QtQGyEcwIAHmAIsANcALAPutYRGYMAJQWufkBdR5fywGDBj4EDALMADp8SzvRmf/1gAAAABJRU5ErkJggg==";

  string constant ARMS_ARMS___AVERAGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNDQ0AAAAKioq////ORpYjAAAAAR0Uk5T////AEAqqfQAAACLSURBVHja7NXBCoAwDAPQJv7/Pyuo4Fw6KqIHzW5d6aM7tIvp5gkDBgwYMPALAEASlAAg4pBagoyItPwEZIQC1vIms96gBmz1AlDCA8BerwAhRKmBQQspwPaW7wH7CzTQC1FrIG/BgASYAywC1AAvAOynhkVgwghAaZwBqt1DuRn9sRgwYOBDwCzAAPPYLPEtxseYAAAAAElFTkSuQmCC";

  string constant ARMS_ARMS___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/fba8c9LAAAA////ojfvEAAAAAR0Uk5T////AEAqqfQAAACaSURBVHja7NXbCoQwDATQzOz//7PaVdy1Ewh4AXX61sAc0tJLfHaOMGDAgAEDrwBIJpMSQAawTgFkRCTxMf8PZIQCvnH8lpoQrAFscQFIQQO6g3EVFWDJK0AIAkDfwCREHegbOARo5QLAZbkS6IUU2NazXYzKKbgYwFlA3A3ob011D2YhAVi6ziTU2wP5MvpjMWDAwIOAQYABACzyLbtfwSVxAAAAAElFTkSuQmCC";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return ARMS_ARMS___AVERAGE_POLAR;
    } else if (headNum == 1) {
      return ARMS_ARMS___AVERAGE;
    } else if (headNum == 2) {
      return ARMS_ARMS___GOLD_PANDA;
    }
    return ARMS_ARMS___AVERAGE_POLAR;
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