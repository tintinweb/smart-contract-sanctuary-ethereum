// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Face {
  using Strings for uint256;

  string constant FACE_FACE___BLACK_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAASUlEQVR42uzSMQoAIAgAQPv/p5uiooSiLc5FETlEjPIYAQD8DMQ2boFWTI0zYBjvORFyYN3gFjg7gkcCAAAAAAAAAAC+BaoAAwDHFQ+pl0nn5AAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAAucDmRV3c////ONIl3AAAAAR0Uk5T////AEAqqfQAAABySURBVHja7NXBCoAgEIThv+393zk2PUSEqANCNXvQ03ysqyC7WLwFAA0gAgP/BLjWMJChLatsCTDcwQ0Y6oCnDpjpoELCEOvulygBERpQohoQnMvsETLcyHcMkWa+5xYAPvC1GTBgwIABAwYMLAQOAQYAdtouT57UYbUAAAAASUVORK5CYII=";

  string constant FACE_FACE___BLUE_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAASklEQVR42uzSsQoAIAgA0ev/f7qGhgiEIiGHc9BFHorSHgMBgeoAI9Z6CzATB235APv4hHtUXSHlCr6ygICAgICAgICAwF+gCzAA1YwP02ZX02sAAAAASUVORK5CYII=";

  string constant FACE_FACE___BLUE_MEDICAL_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAABkSURBVHja7NNBCsAgDETRabz/nVsGUbowSrorP0s1z1FU7WMJAAAAIAUi+qzrPXaYwMul6ykLi/bsCBEatWzP78D7O0PxEmeCMtADVIF2EGDzDvb9/AUAAAAAAAAAgH8CtwADAK54LzvaZ+K/AAAAAElFTkSuQmCC";

  string constant FACE_FACE___BLUE_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NI5DgAgCERRwPvf2UjiEpeC2OmfhoLMCwWSLiMAAC8DJmvUooCv+4wArV+adepeOAPTBRoHvDTGeCQAAAAAAAAAAACAr4AswAA8xC8j72kkzQAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAATUlEQVR42uzSsQoAIAgA0ev/f7pBCIdKqi0uEBd9KkR7fAgI/A8AKZ0DRFBXzYeTAZZrVBsM5+aE6N5M9yMJCAgICAgICAgIfA10AQYAPLEP28WFfGsAAAAASUVORK5CYII=";

  string constant FACE_FACE___BLUE_VERBS_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAASUlEQVR42uzSMQoAIAgAQPv/p4MIImgoDII4B13kFDFKMgIA+B2IFqOeAz3FRtt6/FSPgfQGWeDGEX0iAAAAAAAAAADwFqgCDADOpQ/SPOt3XwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_AND_BLACK_CHECKERED_BANDANA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/AAAA////7jh4eQAAAAN0Uk5T//8A18oNQQAAAGdJREFUeNrslEEOwCAMw5r9/9HjjLYmFZq0g+EG2EJtoK7DUQgQIPi14HFVkxsoPvm2rG1DpVkNlmGb0yKGfNOFjO/aGPFtDhK+D1LAmyR63kXZ8vYtOJ7/AAECBAgQIECA4AvBLcAAr1ofa+nN+qcAAAAASUVORK5CYII=";

  string constant FACE_FACE___BROWN_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFnIFNiW8+////JxjFGwAAAAN0Uk5T//8A18oNQQAAAFJJREFUeNrs0ssKABAYROEZ7//QlOtGEcXi/Auz4WuEwuEIAOB3QGnG3AVUFi1suw+k0s4H3dJ+cgX33H+F2nranq8MAAAAAAAAAAAA8DUQBRgAaWIfthnfdg4AAAAASUVORK5CYII=";

  string constant FACE_FACE___CANDY_CANE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF////sSop////+TKYjgAAAAN0Uk5T//8A18oNQQAAADlJREFUeNrs0cEJADAMAkDT/YcOZIQG+unp/xDMWSYAAADwHZDaLsg9UJl6AQAAAAAAAADwFGgBBgB/px/yKoiShgAAAABJRU5ErkJggg==";

  string constant FACE_FACE___GOLD_FRAMED_MONOCLE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAARUlEQVR42uzR0QkAIAwD0XP/pZ1AKRwIwvU7PELDkkdAQMAUABTAPTUE0A3QP8CuoIFTMuDpCgEBAQEBAQEBAR8BW4ABABTSD+vMiGP9AAAAAElFTkSuQmCC";

  string constant FACE_FACE___GRAY_BEARD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7OsrKy////iqjJwAAAAAN0Uk5T//8A18oNQQAAAGBJREFUeNrs07sOACEIRNEZ//+jdddHaXahMl4tLAhHQkAleQQAAABwBKARtGKA1DPn+xvwt282wIrJwR4414MGvFdhoIx0x+egl5AZpKeE5CSabQQAAAAAAAC4D6gCDADi5h+wR5SUKwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAASklEQVR42uzSsQoAIAgA0ev/f7qGhgiEIiGHc9BFHorSHgMBgeoAI9Z6CzATB235APv4hHtUXSHlCr6ygICAgICAgICAwF+gCzAA1YwP02ZX02sAAAAASUVORK5CYII=";

  string constant FACE_FACE___RED_MEDICAL_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZ1jc/8vLy////zg7CKAAAAAR0Uk5T////AEAqqfQAAABmSURBVHja7NM5DsAgDETRAe5/Z4hlBaXAWNBFf0rAT2ZTu4wAAAAAQqBWn7V8x5KALZfKiAk+kt/CU6A3y/LoDAZQPFqWx4c4Ozi8BXkLx0BLNLB5B/t6/gIAAAAAAAAAwD+BLsAAJuIvL4UfA1oAAAAASUVORK5CYII=";

  string constant FACE_FACE___RED_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZ3ktTAAAA////hP6nfQAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NI5DgAgCERRwPvf2UjiEpeC2OmfhoLMCwWSLiMAAC8DJmvUooCv+4wArV+adepeOAPTBRoHvDTGeCQAAAAAAAAAAACAr4AswAA8xC8j72kkzQAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAATUlEQVR42uzSsQoAIAgA0ev/f7pBCIdKqi0uEBd9KkR7fAgI/A8AKZ0DRFBXzYeTAZZrVBsM5+aE6N5M9yMJCAgICAgICAgIfA10AQYAPLEP28WFfGsAAAAASUVORK5CYII=";

  string constant FACE_FACE___RED_VERBS_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAASUlEQVR42uzSMQoAIAgAQPv/p4MIImgoDII4B13kFDFKMgIA+B2IFqOeAz3FRtt6/FSPgfQGWeDGEX0iAAAAAAAAAADwFqgCDADOpQ/SPOt3XwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_AND_WHITE_CHECKERED_BANDANA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/////1BZ////FD2rYAAAAAN0Uk5T//8A18oNQQAAAGRJREFUeNrslDEOACEMw1L+/+hjZmhSnZAYDGttiTZF6+cRAgQInhZUXqrYW6MnlI56lWY92IbjTpsY8s0UMr4bY8S3OUj4PkgBb5LoeRdly9tdcDz/AQIECBAgQIAAwQ3BJ8AAr5ofa9Y/gbkAAAAASUVORK5CYII=";

  string constant FACE_FACE___WHITE_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////5eXlAAAA////EjtCTgAAAAR0Uk5T////AEAqqfQAAABRSURBVHja7NJBCgAgCERRs/vfOQqMIIWkVfFn40J8iCj1MgIA8DOg4kSzwGgvNQHM+T5pNRBiYNsgDZwdwQVKED4RAAAAAAAAAAAA4CWgCTAA+WUu3beAbwkAAAAASUVORK5CYII=";

  string constant FACE_FACE___WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF8+rr/FBZAAAA////n3VP6QAAAAR0Uk5T////AEAqqfQAAABsSURBVHja7NVRCsAgDAPQNN7/zsMJssEmboGCmH7oVx7YCkURC6sApAYwggb2BHCp7wDuVQGkAngCkAnoTexAuzf/yhEa0KIaEDyPv0+o4UF+ookc5memQL5vhYVWmwEDBgwYMGDAQCJwCDAAPxouH+YfHtgAAAAASUVORK5CYII=";

  string constant FACE_FACE_SPECIAL___HEAD_CONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////////VXz1bAAAAAJ0Uk5T/wDltzBKAAAAdElEQVR42uyUMQrAMAwD7f9/uluhIDkKIdDhMjq6G+w41YenECC4Jqidqgo6gaqXiumkvqiUd1eXBKbhieC4B2/wG5XFaYzuZA9ph++p3wlvdiHne5xYwNttTHm/ziE//gdrmj8RAQIECBAgQIDgp4JHgAEAXLkO+5ppVzQAAAAASUVORK5CYII=";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return FACE_FACE___BLACK_NINJA_MASK;
    } else if (headNum == 1) {
      return FACE_FACE___BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
    } else if (headNum == 2) {
      return FACE_FACE___BLUE_FRAMED_GLASSES;
    } else if (headNum == 3) {
      return FACE_FACE___BLUE_MEDICAL_MASK;
    } else if (headNum == 4) {
      return FACE_FACE___BLUE_NINJA_MASK;
    } else if (headNum == 5) {
      return FACE_FACE___BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (headNum == 6) {
      return FACE_FACE___BLUE_VERBS_GLASSES;
    } else if (headNum == 7) {
      return FACE_FACE___BLUE_AND_BLACK_CHECKERED_BANDANA;
    } else if (headNum == 8) {
      return FACE_FACE___BROWN_FRAMED_GLASSES;
    } else if (headNum == 9) {
      return FACE_FACE___CANDY_CANE;
    } else if (headNum == 10) {
      return FACE_FACE___GOLD_FRAMED_MONOCLE;
    } else if (headNum == 11) {
      return FACE_FACE___GRAY_BEARD;
    } else if (headNum == 12) {
      return FACE_FACE___NONE;
    } else if (headNum == 13) {
      return FACE_FACE___RED_FRAMED_GLASSES;
    } else if (headNum == 14) {
      return FACE_FACE___RED_MEDICAL_MASK;
    } else if (headNum == 15) {
      return FACE_FACE___RED_NINJA_MASK;
    } else if (headNum == 16) {
      return FACE_FACE___RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (headNum == 17) {
      return FACE_FACE___RED_VERBS_GLASSES;
    } else if (headNum == 18) {
      return FACE_FACE___RED_AND_WHITE_CHECKERED_BANDANA;
    } else if (headNum == 19) {
      return FACE_FACE___WHITE_NINJA_MASK;
    } else if (headNum == 20) {
      return FACE_FACE___WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
    } else if (headNum == 21) {
      return FACE_FACE_SPECIAL___HEAD_CONE;
    }
    return FACE_FACE___BLACK_NINJA_MASK;
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