// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Special_Face {
  using Strings for uint256;

  string constant SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////5TMxUGv/////saxS2QAAAAR0Uk5T////AEAqqfQAAABrSURBVHja7NTLCoAwDETRSfz/f5aAaDbRkqJUuNm1MIc2fWibLAEALA/orB4gjQgayt8ICwPSmKAy7znupVDOuychBp8DsWo7qrOFaKLZJah1Cimv3j14zr/6mPiRAAAAAAAAAAD+C+wCDACP0C3R4VTJFQAAAABJRU5ErkJggg==";

  string constant SPECIAL_FACE_FACE_SPECIAL___DRIPPING_HONEY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAaUlEQVR42uzTSw6AIAwA0en9L22wJrpRaUlcmGFDAu2j/IjFhoCAgMDnANVxJhe6B7gGQbWCkZRljFyonwEpHF19C3suSTQriDiJoHWN5DSPYZNA+yHxGsbqK/U7CwgICAgICPwQ2AQYAHSlD8A9jYRxAAAAAElFTkSuQmCC";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT;
    } else if (headNum == 1) {
      return SPECIAL_FACE_FACE_SPECIAL___DRIPPING_HONEY;
    }
    return SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT;
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