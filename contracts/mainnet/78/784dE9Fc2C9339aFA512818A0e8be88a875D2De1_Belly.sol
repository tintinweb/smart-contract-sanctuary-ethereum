// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Belly {
  using Strings for uint256;
  string constant BELLY_BELLY___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/u2r+dZOAAAA////y+E3dgAAAAR0Uk5T////AEAqqfQAAACLSURBVHja7NXRCoAgEETR6/b//xyUkJaaa2APzrzPwRVc2T4GAQIECBCwCGBJBgCzkKRO1ICsfhA+4OzDu0Cr33MG+gYYBSCZwgFYuF0BdYHmFUA8AyNArF9jOAGy+AF4CC4AnoIHoJCpAMUsBZQF12v8HSgJ5lyqnf3WWs/qNv9j0e8sQMBkYBdgAGo1Ksc9IiN9AAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___LARGE_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF2NjY6+vrICAg////l5zFNQAAAAR0Uk5T////AEAqqfQAAACNSURBVHja7NVRCsAgDAPQ2N3/zgMRV7tVzERhrPnPQ0RbHJNBAAEEEEAAPwFE5QUgJiwgMihgtO8JGO47wlogldBAW78ICsg95FSCAJLqFyExQNuvAgkARtgNAFb4PoCdAB4AEMBdcA+wFGifMijACJ2+P1QB9Z3h9ntjXd8BP9bnF0ts5wAC2AycAgwA1VgrnR2xanoAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___LARGE_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vr3t7eAAAA////8+jimgAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NXBCsAgDAPQxv3/Pw88tc6UVZmXJfc8RDDatRkTIECAAAE/AZrLAtCauXCCAaHeiRrw6FPB3vaZ8DGAnjoQ+7mQAUAUqgAwCKcBYBQE7AM4CWACoABMBHaAt4CtAPExoQQMQtLnowq4QQHtZ7Pu76A+6/sfi35nAQIOA7cAAwCbrisS9olduwAAAABJRU5ErkJggg==";

  string constant BELLY_BELLY___LARGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNDQ0RUVFAAAA////OJjWPAAAAAR0Uk5T////AEAqqfQAAAB5SURBVHja7NXBDsAgCANQ6v7/n5d4EjcQNHqxvffFg4A8ixECBAgQIHAJUJpMAKVIE5uwAFWvRA749E1Bon1L2AygJg/ovi94AKCFLAB0wmkA6AUClwE/wsw0hh7gjnPkJ/srLdAfLNVxf99aXz8svM4ECBwGXgEGAAvrKvLEmMJhAAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___REVERSE_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNDQ04eHhAAAA////HDMb1wAAAAR0Uk5T////AEAqqfQAAACNSURBVHja7NVRDoAgDAPQWe9/ZxNAMiBLrAT8sPvvUyMrdk6OCRAgQICAnwBw8wIADjcxEQFNPBEcMORDwZ7mI2EtYGVoAE28EqCAlMuH4CYYID+3fAnKWxBAk68CC7hfgU+AdhcEbAcGIc4vBfqjDKrSxmUCWar9OoOvdV8ofK3PXyy6nQUI2AxcAgwAK0krcUtBw4MAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___SMALL_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFJiYm2dnZ6+vr////U2Ve6gAAAAR0Uk5T////AEAqqfQAAACQSURBVHja7NXbCsAgDAPQLv7/P++COnVT2skKY8l7Dii2SpiMECBAgACBnwBS5AEgTayAiFIQbb8niLrfEV4GcMQO1P2xMAKARjACe3PZcgo2INYjYQeKfhZcgaqfBE8AVwAfAybvINwDwQhAc4L+OKN+yrDtgyTkYYJxpeXXXIyz91qf/1j4OxMg4AysAgwAoeArHyW+HsEAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___SMALL_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vr3t7eAAAA////8+jimgAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NVRCsAgDAPQxt3/zgM/RqdmrBXEseQ/DwTb2jEZEyBAgAABPwGKSwIoxVw4wYBbvRIxoOtTwd72mbApMOwTYXcANWkAV3IA0AhBAGiF7wNYCWAAIABUoQNC04j+H8wCCAGtwPt8qQJumED7T2vdPyG+1ucPi66zAAGLgVOAAQA5UirnEpM64AAAAABJRU5ErkJggg==";

  string constant BELLY_BELLY___SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNDQ0RUVFAAAA////OJjWPAAAAAR0Uk5T////AEAqqfQAAAB4SURBVHja7NXBCsAwCANQ0/3/Pw88jNZOqMpKYck9Dw+tylWMECBAgACBnwCtSwJoTbr4hAcMdSViwNR3BVnte8KhwGvfEU4HoEkDeJIDACMEAcAKBLYCKkxA+DcuDfAVYIXwShtfc2ap1td6/bDwOhMgsBm4BRgAqYAqx9GbaRYAAAAASUVORK5CYII=";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return BELLY_BELLY___GOLD_PANDA;
    } else if (headNum == 1) {
      return BELLY_BELLY___LARGE_PANDA;
    } else if (headNum == 2) {
      return BELLY_BELLY___LARGE_POLAR;
    } else if (headNum == 3) {
      return BELLY_BELLY___LARGE;
    } else if (headNum == 4) {
      return BELLY_BELLY___REVERSE_PANDA;
    } else if (headNum == 5) {
      return BELLY_BELLY___SMALL_PANDA;
    } else if (headNum == 6) {
      return BELLY_BELLY___SMALL_POLAR;
    } else if (headNum == 7) {
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