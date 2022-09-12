// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Face {
  using Strings for uint256;
  string constant FACE_FACE___BLACK_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAAChJREFUKM9jYKArYP///wGEcfgwhMHf2PgBwjh8GMr4//8DwygYGgAATy4M1sWCwhoAAAAASUVORK5CYII=";

  string constant FACE_FACE___BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVHcEw8ULkAAAA6TrlQa/8tPb4PAAAAAnRSTlMAXBRO0OcAAABiSURBVEjH7ZDBDYBACAQJHUAFiFYgVuBd/zWdMfoEnmpkvkyWBYBH0GSOTX4uoJ64gioRT8TNfSVegrgL7gTxEw6Jw5KCQcnXvNoSAbskwrYv8Yq59zWuaJYcoQpFURRfYQDewg9ZzWJFkAAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcExQa/9YnfcAAAAAAXRSTlMAQObYZgAAACBJREFUKM9jYKALsLGBMpyc0Bjshw8/wCGF0DUKBisAAHKxBW66DE8gAAAAAElFTkSuQmCC";

  string constant FACE_FACE___BLUE_MEDICAL_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcExQa/9LYt4AAAAmtXu3AAAAAXRSTlMAQObYZgAAAD5JREFUOMtjYBgFRAAbBtEQIIEAzAeiljIfQFZiGxpag6KHcdUqB1SB0FA0gayVqAIMoaFoFgOtHQWjYNACAB6cCbHdXrxtAAAAAElFTkSuQmCC";

  string constant FACE_FACE___BLUE_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcExQa/9LYt4AAAAmtXu3AAAAAXRSTlMAQObYZgAAADNJREFUOMtjYBhuwDQUCHKQBQJYA1iRBa46MDowZiMLgFSsRhYIXbVq1WqGUTAKRgFeAADeVgsAPDD6gAAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcExQa/9YnfcAAAAAAXRSTlMAQObYZgAAACRJREFUKM9jYKAvkLGAMpRcIDTzI/cDEJbyEaiUXQ3DKBgiAABnJgRI+M+ymwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_VERBS_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcExQa/9YnfcAAAAAAXRSTlMAQObYZgAAACNJREFUKM9jYKAvqKuDMpycIDTz4UMQBhNMBM5AKB4FgxUAAL/BBRFepEkkAAAAAElFTkSuQmCC";

  string constant FACE_FACE___BLUE_AND_BLACK_CHECKERED_BANDANA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAABQa//R3HrCAAAAAXRSTlMAQObYZgAAAE9JREFUOMtjYBgFDAogggVJgAUuCgWcDQwMjBOQBJjSgMAB2ZCZQIBiqlpaWgqKAOfMmRNQBJjQjAAZguY0tRQ0Ac4JaAJMDqMROAoGCgAAl/oMZ4YEhmMAAAAASUVORK5CYII=";

  string constant FACE_FACE___BROWN_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEycgU2Jbz5U14ylAAAAAXRSTlMAQObYZgAAADFJREFUOMtjYBjqgDWANQBFQIBFgAWvgOgEtglsK/Br4RDgQBHgWsC1gGEUjIJRgAIA3JgEkKeR7CAAAAAASUVORK5CYII=";

  string constant FACE_FACE___CANDY_CANE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEyxKin///+RCDhAAAAAAXRSTlMAQObYZgAAABxJREFUOMtjYBgFtAOc6AJMaHzJmaOBNAqGMAAADYsAvrGJKjEAAAAASUVORK5CYII=";

  string constant FACE_FACE___GOLD_FRAMED_MONOCLE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEzqxTc1b1cjAAAAAXRSTlMAQObYZgAAACRJREFUKM9jYBgoYAFjuMAYbjCGK1xNA4wFZziQwmhgGAW0BQBLnQQAC6YzwgAAAABJRU5ErkJggg==";

  string constant FACE_FACE___GRAY_BEARD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEzOzs6ysrLIeI08AAAAAXRSTlMAQObYZgAAAENJREFUOMtjYBgF1AGMDkwOKAKsE1gnoAhwMDAIoAhwMjAkoJrRgGYG48xpqAIMM9PQ7FVLQRNgC0B3WsNo7IwC2gAA+44GwaWR7YcAAAAASUVORK5CYII=";

  string constant FACE_FACE___NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAAA1BMVEVHcEyC+tLSAAAAAXRSTlMAQObYZgAAAA9JREFUKM9jYBgFo4B8AAACQAABjMWrdwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEz/UFmJvgS4AAAAAXRSTlMAQObYZgAAACBJREFUKM9jYKALsLGBMpyc0Bjshw8/wCGF0DUKBisAAHKxBW66DE8gAAAAAElFTkSuQmCC";

  string constant FACE_FACE___RED_MEDICAL_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVHcEwAAAD/UFnWNz////8GGA5XAAAAAnRSTlMAGovxNEIAAABaSURBVEjHY2AYBaOAPMDiwMDApKSkAGFhAYwiDgxKxsZKDCyOAgw4VDgpAYEKLnmgCiFjIFAUwO0MJpAJCnjcyaRsbGyETwEDyAS8XmXCb8MoGAWjYBSMPAAAB3MHHOogHicAAAAASUVORK5CYII=";

  string constant FACE_FACE___RED_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEz/UFneS1MAAAB/PTuWAAAAAXRSTlMAQObYZgAAADNJREFUOMtjYBhuwDQUCHKQBQJYA1iRBa46MDowZiMLgFSsRhYIXbVq1WqGUTAKRgFeAADeVgsAPDD6gAAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEz/UFmJvgS4AAAAAXRSTlMAQObYZgAAACRJREFUKM9jYKAvkLGAMpRcIDTzI/cDEJbyEaiUXQ3DKBgiAABnJgRI+M+ymwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_VERBS_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEz/UFmJvgS4AAAAAXRSTlMAQObYZgAAACNJREFUKM9jYKAvqKuDMpycIDTz4UMQBhNMBM5AKB4FgxUAAL/BBRFepEkkAAAAAElFTkSuQmCC";

  string constant FACE_FACE___RED_AND_WHITE_CHECKERED_BANDANA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEz/////UFnwWuPLAAAAAXRSTlMAQObYZgAAAE9JREFUOMtjYBgFDAogggVJgAUuCgWcDQwMjBOQBJjSgMAB2ZCZQIBiqlpaWgqKAOfMmRNQBJjQjAAZguY0tRQ0Ac4JaAJMDqMROAoGCgAAl/oMZ4YEhmMAAAAASUVORK5CYII=";

  string constant FACE_FACE___WHITE_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///8AAAD7E7aFAAAAAnRSTlMAGovxNEIAAAAzSURBVDjLY2AYbsBqFRCsQRZYwLWAC1ngVQNTA9NqZAGQChQBkBnIAqFgwDAKRsEoQAYAFxgRhhRt9HwAAAAASUVORK5CYII=";

  string constant FACE_FACE___WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAElBMVEVHcEyjMzkAAAD8T1gAAAD///9G/8seAAAAA3RSTlMAOBoQi4FfAAAAbklEQVRIx2NgGBDgQkCexdhhhCtgDQWBEJwKQkMFBUUDBUWMXXEoUFKFKnDCaQHMhACsCphAJgAVAU1QwO3IIFU8jgSaoaTApKQy4EFtTEABUJaQAhNn/FY4GxubEHAiIU+4uDCMglEwCkbBUAEAfAwXLZNwZ40AAAAASUVORK5CYII=";

  string constant FACE_FACE_SPECIAL___HEAD_CONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEz////////mcEUwAAAAAnRSTlMAZ6VFOcMAAACBSURBVDjLY2AYWmABiOBC8LkCQCTrArjA0hAQKRoF4zOFQlSENsAElkIEouACUQ4ginEpTIBh6goQqRUGN1Q1DGgB19QIuABnaNSqVUtDExgQ1oBBA8JlU0H8MCSnq4IEIpAEOEECCUgCTGhGMDCsDA3NQvE/06pVDQyjYBQMEgAAhNwdFtVmPrIAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return FACE_FACE___BLACK_NINJA_MASK;
    } else if (assetNum == 1) {
      return FACE_FACE___BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
    } else if (assetNum == 2) {
      return FACE_FACE___BLUE_FRAMED_GLASSES;
    } else if (assetNum == 3) {
      return FACE_FACE___BLUE_MEDICAL_MASK;
    } else if (assetNum == 4) {
      return FACE_FACE___BLUE_NINJA_MASK;
    } else if (assetNum == 5) {
      return FACE_FACE___BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (assetNum == 6) {
      return FACE_FACE___BLUE_VERBS_GLASSES;
    } else if (assetNum == 7) {
      return FACE_FACE___BLUE_AND_BLACK_CHECKERED_BANDANA;
    } else if (assetNum == 8) {
      return FACE_FACE___BROWN_FRAMED_GLASSES;
    } else if (assetNum == 9) {
      return FACE_FACE___CANDY_CANE;
    } else if (assetNum == 10) {
      return FACE_FACE___GOLD_FRAMED_MONOCLE;
    } else if (assetNum == 11) {
      return FACE_FACE___GRAY_BEARD;
    } else if (assetNum == 12) {
      return FACE_FACE___NONE;
    } else if (assetNum == 13) {
      return FACE_FACE___RED_FRAMED_GLASSES;
    } else if (assetNum == 14) {
      return FACE_FACE___RED_MEDICAL_MASK;
    } else if (assetNum == 15) {
      return FACE_FACE___RED_NINJA_MASK;
    } else if (assetNum == 16) {
      return FACE_FACE___RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (assetNum == 17) {
      return FACE_FACE___RED_VERBS_GLASSES;
    } else if (assetNum == 18) {
      return FACE_FACE___RED_AND_WHITE_CHECKERED_BANDANA;
    } else if (assetNum == 19) {
      return FACE_FACE___WHITE_NINJA_MASK;
    } else if (assetNum == 20) {
      return FACE_FACE___WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
    } else if (assetNum == 21) {
      return FACE_FACE_SPECIAL___HEAD_CONE;
    }
    return FACE_FACE___NONE;
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