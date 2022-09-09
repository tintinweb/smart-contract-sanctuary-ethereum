// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Eyes {
  using Strings for uint256;

  string constant EYES_EYES___ANNOYED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////RU15////TARLqgAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NIxCgAgDEPRRO9/ZxWk4CJUERx+F7P4aEtVL0sAAACvAY1aQg6QXYo1Qn+tgw48v0XI7iAa303AHQAAAAAAAAAAAAB8CzQBBgBe+y+dpF6IIQAAAABJRU5ErkJggg==";

  string constant EYES_EYES___ANNOYED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////m39H////ryVSgQAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NIxCgAgDEPRRO9/ZxWk4CJUERx+F7P4aEtVL0sAAACvAY1aQg6QXYo1Qn+tgw48v0XI7iAa303AHQAAAAAAAAAAAAB8CzQBBgBe+y+dpF6IIQAAAABJRU5ErkJggg==";

  string constant EYES_EYES___ANNOYED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////fqmA////BIOE9gAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NIxCgAgDEPRRO9/ZxWk4CJUERx+F7P4aEtVL0sAAACvAY1aQg6QXYo1Qn+tgw48v0XI7iAa303AHQAAAAAAAAAAAAB8CzQBBgBe+y+dpF6IIQAAAABJRU5ErkJggg==";

  string constant EYES_EYES___BEADY_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAM0lEQVR42uzQsQkAAAgDwbj/0g5gI1gJ93W4IqljAQAAH4DsN04EAAAAAAAAAAAAoxZgAP8uD/8UPkNkAAAAAElFTkSuQmCC";

  string constant EYES_EYES___BEADY_RED_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/wAA////QR00EQAAAAJ0Uk5T/wDltzBKAAAAM0lEQVR42uzQsQkAAAgDwbj/0g5gI1gJ93W4IqljAQAAH4DsN04EAAAAAAAAAAAAoxZgAP8uD/8UPkNkAAAAAElFTkSuQmCC";

  string constant EYES_EYES___BORED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////RU15////TARLqgAAAAR0Uk5T////AEAqqfQAAABKSURBVHja7NIxCgAgEAPBjf7/z2oh2IlYiLBp0g3kOOplEBAQ2AH0rH0KkJQwuiS8AIbA2udHnNPBRxIQEBAQEBAQEBD4EGgCDADtLC+Ve7x4FgAAAABJRU5ErkJggg==";

  string constant EYES_EYES___BORED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////m39H////ryVSgQAAAAR0Uk5T////AEAqqfQAAABKSURBVHja7NIxCgAgEAPBjf7/z2oh2IlYiLBp0g3kOOplEBAQ2AH0rH0KkJQwuiS8AIbA2udHnNPBRxIQEBAQEBAQEBD4EGgCDADtLC+Ve7x4FgAAAABJRU5ErkJggg==";

  string constant EYES_EYES___BORED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////fqmA////BIOE9gAAAAR0Uk5T////AEAqqfQAAABKSURBVHja7NIxCgAgEAPBjf7/z2oh2IlYiLBp0g3kOOplEBAQ2AH0rH0KkJQwuiS8AIbA2udHnNPBRxIQEBAQEBAQEBD4EGgCDADtLC+Ve7x4FgAAAABJRU5ErkJggg==";

  string constant EYES_EYES___DILATED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////8vLyPENq////Nu0FrAAAAAR0Uk5T////AEAqqfQAAABPSURBVHja7NIxCgAgDEPRRO9/Z0VQ0K12EOR3ypIHLVVNjgAAvgdsHyEGWJK3EAN6rYziCnFAE9ANkF4hf0Q+EQAAAAAAAAAAAOAt0AQYAPXQL23sLzNPAAAAAElFTkSuQmCC";

  string constant EYES_EYES___DILATED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////8vLyiW8+////PLTdmgAAAAR0Uk5T////AEAqqfQAAABPSURBVHja7NIxCgAgDEPRRO9/Z0VQ0K12EOR3ypIHLVVNjgAAvgdsHyEGWJK3EAN6rYziCnFAE9ANkF4hf0Q+EQAAAAAAAAAAAOAt0AQYAPXQL23sLzNPAAAAAElFTkSuQmCC";

  string constant EYES_EYES___DILATED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////8vLybpZw////CRrrggAAAAR0Uk5T////AEAqqfQAAABPSURBVHja7NIxCgAgDEPRRO9/Z0VQ0K12EOR3ypIHLVVNjgAAvgdsHyEGWJK3EAN6rYziCnFAE9ANkF4hf0Q+EQAAAAAAAAAAAOAt0AQYAPXQL23sLzNPAAAAAElFTkSuQmCC";

  string constant EYES_EYES___NEUTRAL_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////RU15////TARLqgAAAAR0Uk5T////AEAqqfQAAABESURBVHja7NIhDgAgEAPBveP/f0ZgQMIJAtmauhFNacUgIPA/AGvvAkQw9wGQA8hbQHkDjyQgICAgICAgICDwNtAFGAA45C+xcgTaRAAAAABJRU5ErkJggg==";

  string constant EYES_EYES___NEUTRAL_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////m39H////ryVSgQAAAAR0Uk5T////AEAqqfQAAABESURBVHja7NIhDgAgEAPBveP/f0ZgQMIJAtmauhFNacUgIPA/AGvvAkQw9wGQA8hbQHkDjyQgICAgICAgICDwNtAFGAA45C+xcgTaRAAAAABJRU5ErkJggg==";

  string constant EYES_EYES___NEUTRAL_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF////bpZw////eWiTSQAAAAN0Uk5T//8A18oNQQAAADtJREFUeNrs0aERACAQA8E8/ReNQKGYHwSCjTm3JhmXCwAAOALJ3j5Qq/UMcCMAAAAAAAAAAPA3MAUYACONH+1xXxmfAAAAAElFTkSuQmCC";

  string constant EYES_EYES___SQUARE_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////RU15////TARLqgAAAAR0Uk5T////AEAqqfQAAABHSURBVHja7NIxCgAgDATBTfz/ny0EsdUUAdk01w3cEUbxEBD4HwCOuAeICHY8AbmA7AOKFcoj+okCAgICAgICAgICrcAUYADuMS+B/RNN9AAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SQUARE_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////m39H////ryVSgQAAAAR0Uk5T////AEAqqfQAAABHSURBVHja7NIxCgAgDATBTfz/ny0EsdUUAdk01w3cEUbxEBD4HwCOuAeICHY8AbmA7AOKFcoj+okCAgICAgICAgICrcAUYADuMS+B/RNN9AAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SQUARE_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////fqmA////BIOE9gAAAAR0Uk5T////AEAqqfQAAABESURBVHja7NIhDgAgEAPBveP/f0ZgQMIJAtmauhFNacUgIPA/AGvvAkQw9wGQA8hbQHkDjyQgICAgICAgICDwNtAFGAA45C+xcgTaRAAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SURPRISED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////P0Zv////5B9cXwAAAAR0Uk5T////AEAqqfQAAABKSURBVHja7NIxDgAgCATBRf//Z2NhoiWhUJOluYopDujFQUDgeQDOzAJEsGcWIFqbmys/BMod1K/gKwsICAgICAgICAhcBYYAAwB5ZS95gG08WwAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SURPRISED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////j3RB////Zdl8wQAAAAR0Uk5T////AEAqqfQAAABKSURBVHja7NIxDgAgCATBRf//Z2NhoiWhUJOluYopDujFQUDgeQDOzAJEsGcWIFqbmys/BMod1K/gKwsICAgICAgICAhcBYYAAwB5ZS95gG08WwAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SURPRISED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8vLy////c5x1////YGRGSwAAAAR0Uk5T////AEAqqfQAAABKSURBVHja7NIxDgAgCATBRf//Z2NhoiWhUJOluYopDujFQUDgeQDOzAJEsGcWIFqbmys/BMod1K/gKwsICAgICAgICAhcBYYAAwB5ZS95gG08WwAAAABJRU5ErkJggg==";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return EYES_EYES___ANNOYED_BLUE_EYES;
    } else if (headNum == 1) {
      return EYES_EYES___ANNOYED_BROWN_EYES;
    } else if (headNum == 2) {
      return EYES_EYES___ANNOYED_GREEN_EYES;
    } else if (headNum == 3) {
      return EYES_EYES___BEADY_EYES;
    } else if (headNum == 4) {
      return EYES_EYES___BEADY_RED_EYES;
    } else if (headNum == 5) {
      return EYES_EYES___BORED_BLUE_EYES;
    } else if (headNum == 6) {
      return EYES_EYES___BORED_BROWN_EYES;
    } else if (headNum == 7) {
      return EYES_EYES___BORED_GREEN_EYES;
    } else if (headNum == 8) {
      return EYES_EYES___DILATED_BLUE_EYES;
    } else if (headNum == 9) {
      return EYES_EYES___DILATED_BROWN_EYES;
    } else if (headNum == 10) {
      return EYES_EYES___DILATED_GREEN_EYES;
    } else if (headNum == 11) {
      return EYES_EYES___NEUTRAL_BLUE_EYES;
    } else if (headNum == 12) {
      return EYES_EYES___NEUTRAL_BROWN_EYES;
    } else if (headNum == 13) {
      return EYES_EYES___NEUTRAL_GREEN_EYES;
    } else if (headNum == 14) {
      return EYES_EYES___SQUARE_BLUE_EYES;
    } else if (headNum == 15) {
      return EYES_EYES___SQUARE_BROWN_EYES;
    } else if (headNum == 16) {
      return EYES_EYES___SQUARE_GREEN_EYES;
    } else if (headNum == 17) {
      return EYES_EYES___SURPRISED_BLUE_EYES;
    } else if (headNum == 18) {
      return EYES_EYES___SURPRISED_BROWN_EYES;
    } else if (headNum == 19) {
      return EYES_EYES___SURPRISED_GREEN_EYES;
    }
    return EYES_EYES___ANNOYED_BLUE_EYES;
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