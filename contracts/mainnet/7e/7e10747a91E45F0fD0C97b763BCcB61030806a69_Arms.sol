// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Arms {
  using Strings for uint256;
  string constant ARMS_ARMS___AVERAGE_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA2dnZ////Lc7C2wAAAAR0Uk5T////AEAqqfQAAACJSURBVHja7NXBCoAwDAPQJv7/Pyuo4Fw6KqIHzW5t6aM7dIvp5gkDBgwYMPALAEASlAAg4lBagoyItP0EZIQC1vamsmZQA7Z+ASjhAWDvV4AQojTAYIQUYJvle8B+Aw30QtQGyEcwIAHmAIsANcALAPutYRGYMAJQWufkBdR5fywGDBj4EDALMADp8SzvRmf/1gAAAABJRU5ErkJggg==";

  string constant ARMS_ARMS___AVERAGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAKioqMDAw////xGf92wAAAAV0Uk5T/////wD7tg5TAAAAl0lEQVR42uzVyQrDMAwEUM2o///N2RqokxEohPTQjn2ybD1k8BKvmy0MGDBgwMBfAACKQQsAIj6m5kFFRJl+ACpCAVv6MLNF0APe+QJQwgPAnq8AIZRAjtG8CiTHKPNrwL4DDZyF6BVQl2BAAqwBNgFqgD0gl3U835o1nGicRKYGcu5oXWeA6u2hfBn9sRgwYOCHgEmAAQAuljwQRH1rwAAAAABJRU5ErkJggg==";

  string constant ARMS_ARMS___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF+dZOAAAA1bY+7MtK//jb8uvQ////JJEdSwAAAAd0Uk5T////////ABpLA0YAAACsSURBVHja7NXhCsIwDATgXFJ9/0e2pgh2u8DBEEGz/Vra+2hgbe1+8bEGGmiggQb+AgBQfEgAMOxtyMwqwor4zO9ARTBgxbeRFAY0ABknABU4wFcwu1CAV54BRCCAJRB7NZaqAZn3vepxGciyAGA1WwBnoQCO+RREYHwdsE8BNxnwGnARcA64BsRznp93TZYDwp/owYGYL6TtDDg7e5yejH2xNNBAAz8EPAQYAFoHWgaq+LesAAAAAElFTkSuQmCC";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return ARMS_ARMS___AVERAGE_POLAR;
    } else if (assetNum == 1) {
      return ARMS_ARMS___AVERAGE;
    } else if (assetNum == 2) {
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