// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Mouth {
  using Strings for uint256;

  string constant MOUTH_MOUTH___ANXIOUS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAP0lEQVR42uzRMQoAMAgEsPP/n+7QxaW02DUHTkJUTH0mAAAAAHgCdi/JeIO0mp1wme6NAAAAAAAAAIBTlgADAK4vD/cR1jg5AAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___BABY_TOOTH_SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAADpJREFUeNrs0TEKADAIBMEz/390wD5gsJ1tlQExZ1kAAAAAMAMy33lNu+UJ5Y0AAAAAAAAAgP+uAAMAa4of8AL3yZMAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___BLUE_LIPSTICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/S2Le////rt5oUQAAAAN0Uk5T//8A18oNQQAAADtJREFUeNrs0cEJACEQBMH28g9aAxBO2G91AMXA9A0LAAAAAM9AjYDWqcmC+pvgRgAAAAAAAADArS3AAE2zH+2klLMNAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___FULL_MOUTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFNTU1AAAA////0A2dowAAAAN0Uk5T//8A18oNQQAAAEBJREFUeNrs0iEOACAMA8DC/x8NjpBgBpKrmWhzaumPCQAAAPwBJPutAqmuTlWbuQZWF38AAAAAAAAAAChmCDAAHnkf6fOp8jgAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___MISSING_BOTTOM_TOOTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAADhJREFUeNrs0cEJACAQA8HE/ov2YwN64Gu2gCGQrGEBAAAAwCcgp/cFadN4AQAAAAAAAABw3RZgABpJH+jnE47kAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___NERVOUS_MOUTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRsQkAIAADwXf/pQVxARWs7iHtNWk8FgAAAAA+AdXaPbAJLwAAAAAAAAAATpsCDACa4Q/1sglxFAAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___OPEN_MOUTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzRsQkAMAwDQWX/pQOuDSkEqe57HwLnlAUAAAAAv4BMzYLnvS8AAAAAAAAAANauAAMAr3QP90EGRPYAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___PINK_LIPSTICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF4GDl////yw5CGAAAAAJ0Uk5T/wDltzBKAAAAOUlEQVR42uzRsQkAMAwDQXn/pQOpAw6ove99CJwpCwAAAAC+gaQCcmsWrPfeCAAAAAAAAAB4dgQYAJnfD/XVqKI6AAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___RED_LIPSTICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZ3ktT////91YocAAAAAN0Uk5T//8A18oNQQAAADtJREFUeNrs0cEJACEQBMH28g9aAxBO2G91AMXA9A0LAAAAAM9AjYDWqcmC+pvgRgAAAAAAAADArS3AAE2zH+2klLMNAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___SAD_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzRsQkAMAwDQXn/pQPp0pkYXN3X4hqlhgUAAAAAW0Bu/0D6Gy8AAAAAAAAAAJ6OAAMAxAUP+bDZ4t4AAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___SMILE_WITH_BUCK_TEETH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAADpJREFUeNrs0TEKADAIBMEz/390IH1AtJ1tlQExZ1kAAAAA0APS3/lNX6sTqrwRAAAAAAAAADDoCjAAYUAf7yk/D1EAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___SMILE_WITH_PIPE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFzs7OiW8+AAAA////Igr54gAAAAR0Uk5T////AEAqqfQAAABYSURBVHja7NNLCsAgEATRGr3/nYMLdxpCGiKB6o2recwH6WEQEPgfABlABrBs4DkA4Q44fQXCDsiBbIR9/T3Q5lP1coltpEb8zgICAgICAgICAt8ClwADAGw7L7BSiUgtAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRMQoAMAgDwPj/TwvdC4LgdFkTbklqmQAAAABgBmS++bUvXgAAAAAAAAAA3AMtwADDAQ/5B23EaQAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___SMIRK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAPElEQVR42uzRwQkAIAADsXP/pcUNREEQ0nebTxuXCQAAAP4C6hBoo9bGvgugFTcCAAAAAAAAAN4DU4ABAIuXD/QMyW3bAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___TINY_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRsQkAMAwDQWX/peMBDCkEqe5rcY1yygIAAACAj0CmDnhsvAAAAAAAAAAA2LoCDADZJA/7BAcUuAAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___TINY_SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRsQ0AMAgDQbP/0skEERES1X1rdA2pYQEAAADAGpDOxXO++QIAAAAAAAAA4L8jwADZmg/7DSgAAAAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___TONGUE_OUT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA4GDl////7QoSFwAAAAN0Uk5T//8A18oNQQAAADhJREFUeNrs0YEJACAMA8G0+w8tzlCwCPcDHIGkhwUAAAAAz4DcZguqehlwIwAAAAAAAMCPwBFgAI13H/PplSVCAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___TOOTHY_SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAAD1JREFUeNrs0TEKADAIA8C0/390oUO3guJ6GVwMB2L2MAEAAABADUi989veDE5Yb3gjAAAAAAAAAKCVI8AAYUAf76VMPZsAAAAASUVORK5CYII=";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return MOUTH_MOUTH___ANXIOUS;
    } else if (headNum == 1) {
      return MOUTH_MOUTH___BABY_TOOTH_SMILE;
    } else if (headNum == 2) {
      return MOUTH_MOUTH___BLUE_LIPSTICK;
    } else if (headNum == 3) {
      return MOUTH_MOUTH___FULL_MOUTH;
    } else if (headNum == 4) {
      return MOUTH_MOUTH___MISSING_BOTTOM_TOOTH;
    } else if (headNum == 5) {
      return MOUTH_MOUTH___NERVOUS_MOUTH;
    } else if (headNum == 6) {
      return MOUTH_MOUTH___OPEN_MOUTH;
    } else if (headNum == 7) {
      return MOUTH_MOUTH___PINK_LIPSTICK;
    } else if (headNum == 8) {
      return MOUTH_MOUTH___RED_LIPSTICK;
    } else if (headNum == 9) {
      return MOUTH_MOUTH___SAD_FROWN;
    } else if (headNum == 10) {
      return MOUTH_MOUTH___SMILE_WITH_BUCK_TEETH;
    } else if (headNum == 11) {
      return MOUTH_MOUTH___SMILE_WITH_PIPE;
    } else if (headNum == 12) {
      return MOUTH_MOUTH___SMILE;
    } else if (headNum == 13) {
      return MOUTH_MOUTH___SMIRK;
    } else if (headNum == 14) {
      return MOUTH_MOUTH___TINY_FROWN;
    } else if (headNum == 15) {
      return MOUTH_MOUTH___TINY_SMILE;
    } else if (headNum == 16) {
      return MOUTH_MOUTH___TONGUE_OUT;
    } else if (headNum == 17) {
      return MOUTH_MOUTH___TOOTHY_SMILE;
    }
    return MOUTH_MOUTH___ANXIOUS;
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