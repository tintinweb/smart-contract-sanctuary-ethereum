// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Head {
  using Strings for uint256;

  string constant HEAD_HEAD___ALASKAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNjY2AAAAMDAw////PgG2ygAAAAR0Uk5T////AEAqqfQAAACISURBVHja7NThCoAgDATg3fn+71yMkjKyplEktx/KftyHTJilzrInAPv8BYMCACrtNQAzg+c8urRBwODnegcBWlFEcAa8lz8Hyhe8DRzy0RkMACwCvdq/kcxCHOAOYBhwYQMgdQFsAGaBWTjP1zYSkONoXGnAulG01gUIECBAgAABAv4FTAIMAG5jLR6UfubsAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___ALASKAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6enpAAAANTU1////jWc6HwAAAAR0Uk5T////AEAqqfQAAACUSURBVHja7NRLCsAgDATQjN7/zk1D7MeiGIvQwsyi4CKvGoOSX0YIfBiAprUaAZA0sEIt9VUYSBCLL8KAXDID6J815RsFMnzngJ8l2sRyck9bWARAnkBDkP4G9g72t9AFYINgxBSAMgUIAybgnCPM3EKd+CAN1a8DagHxF+nexKknDUf4rBMgQIAAAQIECPwM2AQYAOuDLQsRxCddAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___ALASKAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA2tra/////k9lSwAAAAR0Uk5T////AEAqqfQAAACISURBVHja7NThCoAgDATg3fn+71yMkjKyplEktx/KftyHTJilzrInAHz+gkEBAJX2GoCZwXMeXdogYPBzvYMArSgiOAPey58D5QveBg756AwGABaBXu3fSGYhDnAHMAy4sAGQugA2ALPALJznaxsJyHE0rjRg3Sha6wIECBAgQIAAAf8CJgEGAH4dLR+JycpCAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF+NVO/OyuAAAA////OoRSFwAAAAR0Uk5T////AEAqqfQAAACiSURBVHja7NThCoMwDATgu/P933lLaqVDrA1D2ODyp1q4z9JIsH1ZMPC7gKSbjTkgEpFQVqwktQ6IeBczFsnw4n0dQAJD5UYRaF9t6SaocAcZ3Y/RNZW60I+9L7i6wwcB4AMAy//B0Yn5EebA0MMywOFPaI9V4FTlNi7lHwPOgqoDRWv5yUSSDuNymtyNNKlPFI91AwYMGDBgwICB/wJeAgwApQ8tBLod1hEAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNTU1AAAAMDAw////O0q5OAAAAAR0Uk5T////AEAqqfQAAACSSURBVHja7NThCoAgDATg3fX+75yU1cIcrSAMbn8K4T5w6mx6WSZgWADAjaU+ADPDGlrKLd0HrAStVv1NAKQ1RSLTg0ZgpgfbLk753DGi3QI+BS7yvU0MDrBWcA3CJpJO4INT8ACTwFkI8n2Ah7B8s4B/UAzywUQqD2ov4NFIA9xE0VgXIECAAAECBAj4EzALMADGWCy5zDUp4wAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___HIMALAYAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6enpAAAANTU1////jWc6HwAAAAR0Uk5T////AEAqqfQAAACbSURBVHja7NTdCoAgDAXgHX3/d67jTxSVOYUoOLtIGe2zVGZxMkzAdwEAD4k2gBACK5CCIxP9AF+nAEsBlIQTsF2MAHnp8jAfQIGVa8068GcowHUKqbACeYwvA2XjbZv47kGuq5vY+oRbwLZrUKde4BSvAleC+xjngLMAb0NBX32jIx2PcaylAbWjqK0LECBAgAABAgT8C1gEGABSayzBE1N5cAAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___HIMALAYAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA2dnZ////Lc7C2wAAAAR0Uk5T////AEAqqfQAAACSSURBVHja7NThCoAgDATg3fX+75yU1cIcrSAMbn8K4T5w6mx6WSZgWADAjaU+ADPDGlrKLd0HrAStVv1NAKQ1RSLTg0ZgpgfbLk753DGi3QI+BS7yvU0MDrBWcA3CJpJO4INT8ACTwFkI8n2Ah7B8s4B/UAzywUQqD2ov4NFIA9xE0VgXIECAAAECBAj4EzALMADGWCy5zDUp4wAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNTU1AAAAMDAw////O0q5OAAAAAR0Uk5T////AEAqqfQAAACPSURBVHja7NRRDoAgDAPQtt7/ziJRRCPEYWI0aX+Uj73IkGF6GBj4MMCU1uoOQAKphjnbKgQASw2wP4OAcIqCwFlQcAsTb35AtwfH8FXgor61ia8DyllfGW+itAsaOYUKkEZ+pBpg9Drr0AOFgSRUt6Fd35lI6T6VNMdJf6SxxGPdgAEDBgwYMGDgZ8AswAAVBCy7Rkg4RQAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6enpAAAANDQ0////w+enbwAAAAR0Uk5T////AEAqqfQAAACMSURBVHja7NTBCoQwDEXR3PT//1ls7EhdKEkHmYGXTckix9InsbZYJuCHAeCmfQZwd/pcHz3aJOBgvYguC9hUWaCxfziuECfZR7S4t40zDfS5D+CVFCaglMIXgHjEMrDyH7SR4SDIx3ip14GrQHsdmAUqG+mMAYorDcZG0VoXIECAAAECBAj4L2ATYAAbSy1TusT+8AAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA2dnZ////Lc7C2wAAAAR0Uk5T////AEAqqfQAAACPSURBVHja7NRRDoAgDAPQtt7/ziJRRCPEYWI0aX+Uj73IkGF6GBj4MMCU1uoOQAKphjnbKgQASw2wP4OAcIqCwFlQcAsTb35AtwfH8FXgor61ia8DyllfGW+itAsaOYUKkEZ+pBpg9Drr0AOFgSRUt6Fd35lI6T6VNMdJf6SxxGPdgAEDBgwYMGDgZ8AswAAVBCy7Rkg4RQAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___REVERSE_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNDQ06urqAAAA////wQvNpgAAAAR0Uk5T////AEAqqfQAAACWSURBVHja7NThCoAgDATg3fX+71yW2TCCziAKbj9ShH1iG4vpYYSBzwIkbxxdAwTALWmNdHQfwJIYNZYtdACRAhowlRvXrJpcPso/KES9tS3Uyrjn41j5KtDykTaUAPQAxoBWQhmI1AoDT6hCaqOBKvShAWdBbKTnQC9Qn0hMBDk00sg0UTzWDRgwYMCAAQMG/gTMAgwAmgQs4cxGUccAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNTU1AAAAMDAw////O0q5OAAAAAR0Uk5T////AEAqqfQAAACPSURBVHja7NRLCsAgDATQzPT+d26VWqrUT3RjYbIRxDwwgbFjsUzAvgCAzkUbgJmFDsQKZ7gYB8LzSBSnFyjLAfCrn3DMgKP91S0MfmBfAMNLaAO8axYg3wIXAU6sMQecW2AxAzqBTGj11wMFz/QjA38iXUGQvlBNk16kASlRFOsCBAgQIECAAAH/Ak4BBgDKniynPHtV8wAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNDQ0AAAA5+fn////Ac5PVwAAAAR0Uk5T////AEAqqfQAAACdSURBVHja7NTbCsMwDANQufn/f16um1aoiVYGG8gvSQs6hjgE5WbBwM8CEbHx6xoIADFCvejXPoAaPGbVLXQABxU0oLSOvfHs3wTlDBpRg63pa9HGOIPgVQTGOSygbiSAcrT5BECsVQaW8MzLAAvjW5zCGVCncBN4F5L89wCaZHqTkxeJ7kKSz560oPKzbsCAAQMGDBgw8F/AQ4ABACgBLQf6s5JuAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA29vb////sM/4OwAAAAR0Uk5T////AEAqqfQAAACPSURBVHja7NRLCsAgDATQzPT+d26VWqrUT3RjYbIRxDwwgbFjsUzAvgCAzkUbgJmFDsQKZ7gYB8LzSBSnFyjLAfCrn3DMgKP91S0MfmBfAMNLaAO8axYg3wIXAU6sMQecW2AxAzqBTGj11wMFz/QjA38iXUGQvlBNk16kASlRFOsCBAgQIECAAAH/Ak4BBgDKniynPHtV8wAAAABJRU5ErkJggg==";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return HEAD_HEAD___ALASKAN_BLACK_BEAR;
    } else if (headNum == 1) {
      return HEAD_HEAD___ALASKAN_PANDA_BEAR;
    } else if (headNum == 2) {
      return HEAD_HEAD___ALASKAN_POLAR_BEAR;
    } else if (headNum == 3) {
      return HEAD_HEAD___GOLD_PANDA;
    } else if (headNum == 4) {
      return HEAD_HEAD___HIMALAYAN_BLACK_BEAR;
    } else if (headNum == 5) {
      return HEAD_HEAD___HIMALAYAN_PANDA_BEAR;
    } else if (headNum == 6) {
      return HEAD_HEAD___HIMALAYAN_POLAR_BEAR;
    } else if (headNum == 7) {
      return HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR;
    } else if (headNum == 8) {
      return HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR;
    } else if (headNum == 9) {
      return HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR;
    } else if (headNum == 10) {
      return HEAD_HEAD___REVERSE_PANDA_BEAR;
    } else if (headNum == 11) {
      return HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR;
    } else if (headNum == 12) {
      return HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR;
    } else if (headNum == 13) {
      return HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR;
    }
    return HEAD_HEAD___ALASKAN_BLACK_BEAR;
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