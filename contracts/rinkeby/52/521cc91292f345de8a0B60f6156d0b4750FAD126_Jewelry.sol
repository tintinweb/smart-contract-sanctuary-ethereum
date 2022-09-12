// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Jewelry {
  using Strings for uint256;
  string constant JEWELRY_JEWELRY___BLUE_BRACELET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/5eXl////qSQL7QAAAAN0Uk5T//8A18oNQQAAAEJJREFUeNrs0rENACAMxEA/+w+NFLEAgQrsMsUVrzAOQ0BAQEBAQEDgfYBd+TqQdSDdDUKV/oipfCQBAQGBP4EpwABFQB/f2QegEQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___BLUE_SPORTS_WATCH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFOk65AAAA5eXlS2Le////5FMLwAAAAAV0Uk5T/////wD7tg5TAAAAR0lEQVR42uzSsQ0AIAwDQdth/5mBBSiSguZ/gJNiRWuYAAAAAAAAAAB+A54AOvUB26qaA2kDSe4JoxGPER4JAAAAAODZFmAArBE/opL70I0AAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF97Z08dGH159l////5eXl6sU3////nCw5OwAAAAd0Uk5T////////ABpLA0YAAACGSURBVHja7NTBCsAwCANQq3b//8kT28MusyWFwSBhlx3ykE2U6zBCgAABAgQIbAH99eU3gD9K3ZGP2HcGqIAYoWWqAcrf6E0yzcE9mP0QMGD0zawUVoAdAtGOR1HAMqowILOPAzr6IOAtqmMAeJFUV/36oPhYZccvkmd4lQkQIEDgK+AWYAAcfV2fh6w3wAAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___DOUBLE_GOLD_CHAINS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6sU35eXl////NFtlvAAAAAN0Uk5T//8A18oNQQAAAF9JREFUeNrs08EKACEIRdH3/P+PLiIKhkHKWc51JSQHzVJ8DAEAAAAAABwBKpQ9TvSSXgCW52FPXLkDdWOE86qkhfCISBpIt7BHqK5xjVB+B3ME/gIAAAAAAMCvgCbAAFrpH7EtfnnrAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___DOUBLE_SILVER_CHAINS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7O5eXl////R8rVTwAAAAN0Uk5T//8A18oNQQAAAF9JREFUeNrs08EKACEIRdH3/P+PLiIKhkHKWc51JSQHzVJ8DAEAAAAAABwBKpQ9TvSSXgCW52FPXLkDdWOE86qkhfCISBpIt7BHqK5xjVB+B3ME/gIAAAAAAMCvgCbAAFrpH7EtfnnrAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN_WITH_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6sU35eXl////NFtlvAAAAAN0Uk5T//8A18oNQQAAAGxJREFUeNrs1EEOgCAMRNEZ7n9oJcbEjVMBjZvfLcxLQxvUFksAAAAAAACPAE1cexfw5UieeQON3rpvITQQp3AKKZ/HeAgxX+xBF3K+WiSryFeA9loBpFL4GHDP//uIzeZLAwAAAAAYqE2AAQAhyB+fAJ91QQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN_WITH_RED_RUBY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6sU35eXlnjMz3ZGRhSgo////gYUuFQAAAAZ0Uk5T//////8As7+kvwAAAHJJREFUeNrs1MEOgDAIA9AW2P//shpj4kVww8RLdx19IbAMo3kgQIAAAQIEvAKwUPYtwNsVuDIDzFY9t5A0kG7hErJ8vsZTSPPFOziEPF89JKLIVwDc0QHgZoYOsOejAxARPw9xkPrSBAgQIEDAxNkEGADT6U8SwyRYtgAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6sU35eXl////NFtlvAAAAAN0Uk5T//8A18oNQQAAAFNJREFUeNrs00EKACAIRNGZ7n/oQAjaJGXt+rPNHpKmdhkBAAAAAABsASqUvQU8HcmVN9Bp1bqFpIF0CkPI7udjtCKu74Ej/AUAAAAAAIC/gC7AAGtpH89tNxW/AAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___GOLD_STUD_EARRINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAMklEQVR42uzQoREAAAwCMbr/0jXdAFOR11wEmbIAAJ+BNEsnAgAAAAAAAAAAAMC1AgwA/SYP/+cPiukAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___GOLD_WATCH_ON_LEFT_WRIST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6sU32btH5eXlAAAA////M7UYqgAAAAV0Uk5T/////wD7tg5TAAAASElEQVR42uzSsREAMAhCUcTsP3PMAimk/di/O1SdMAIAAAAAAAAACIFOgeoA0GQPlGYqB7zege1XIbrCGOYTAQAAAAC+uQIMAErLP5ROwBakAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___LEFT_HAND_GOLD_RINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAM0lEQVR42uzRwQkAMAwDscv+S2eIUvKRBxCGax4XAAAAAAAAAAAwdfigVAAAAIDfwAowAAE2D/3g10aZAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___LEFT_HAND_SILVER_RINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFzs7O////TowvlgAAAAJ0Uk5T/wDltzBKAAAAM0lEQVR42uzRwQkAMAwDscv+S2eIUvKRBxCGax4XAAAAAAAAAAAwdfigVAAAAIDfwAowAAE2D/3g10aZAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___RED_BRACELET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZ5eXl////buXvrwAAAAN0Uk5T//8A18oNQQAAAEJJREFUeNrs0rENACAMxEA/+w+NFLEAgQrsMsUVrzAOQ0BAQEBAQEDgfYBd+TqQdSDdDUKV/oipfCQBAQGBP4EpwABFQB/f2QegEQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___RED_SPORTS_WATCH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFuTpBAAAA5eXl3ktT////lr6DwQAAAAV0Uk5T/////wD7tg5TAAAAR0lEQVR42uzSsQ0AIAwDQdth/5mBBSiSguZ/gJNiRWuYAAAAAAAAAAB+A54AOvUB26qaA2kDSe4JoxGPER4JAAAAAODZFmAArBE/opL70I0AAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN_WITH_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7O5eXl////R8rVTwAAAAN0Uk5T//8A18oNQQAAAGxJREFUeNrs1EEOgCAMRNEZ7n9oJcbEjVMBjZvfLcxLQxvUFksAAAAAAACPAE1cexfw5UieeQON3rpvITQQp3AKKZ/HeAgxX+xBF3K+WiSryFeA9loBpFL4GHDP//uIzeZLAwAAAAAYqE2AAQAhyB+fAJ91QQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN_WITH_RED_RUBY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFzs7O5eXlnjMz3ZGRhSgo////PAEFCgAAAAZ0Uk5T//////8As7+kvwAAAHJJREFUeNrs1MEOgDAIA9AW2P//shpj4kVww8RLdx19IbAMo3kgQIAAAQIEvAKwUPYtwNsVuDIDzFY9t5A0kG7hErJ8vsZTSPPFOziEPF89JKLIVwDc0QHgZoYOsOejAxARPw9xkPrSBAgQIEDAxNkEGADT6U8SwyRYtgAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7O5eXl////R8rVTwAAAAN0Uk5T//8A18oNQQAAAFNJREFUeNrs00EKACAIRNGZ7n/oQAjaJGXt+rPNHpKmdhkBAAAAAABsASqUvQU8HcmVN9Bp1bqFpIF0CkPI7udjtCKu74Ej/AUAAAAAAIC/gC7AAGtpH89tNxW/AAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___SILVER_STUD_EARRINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFzs7O////TowvlgAAAAJ0Uk5T/wDltzBKAAAAMklEQVR42uzQoREAAAwCMbr/0jXdAFOR11wEmbIAAJ+BNEsnAgAAAAAAAAAAAMC1AgwA/SYP/+cPiukAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return JEWELRY_JEWELRY___BLUE_BRACELET;
    } else if (assetNum == 1) {
      return JEWELRY_JEWELRY___BLUE_SPORTS_WATCH;
    } else if (assetNum == 2) {
      return
        JEWELRY_JEWELRY___DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION;
    } else if (assetNum == 3) {
      return JEWELRY_JEWELRY___DOUBLE_GOLD_CHAINS;
    } else if (assetNum == 4) {
      return JEWELRY_JEWELRY___DOUBLE_SILVER_CHAINS;
    } else if (assetNum == 5) {
      return JEWELRY_JEWELRY___GOLD_CHAIN_WITH_MEDALLION;
    } else if (assetNum == 6) {
      return JEWELRY_JEWELRY___GOLD_CHAIN_WITH_RED_RUBY;
    } else if (assetNum == 7) {
      return JEWELRY_JEWELRY___GOLD_CHAIN;
    } else if (assetNum == 8) {
      return JEWELRY_JEWELRY___GOLD_STUD_EARRINGS;
    } else if (assetNum == 9) {
      return JEWELRY_JEWELRY___GOLD_WATCH_ON_LEFT_WRIST;
    } else if (assetNum == 10) {
      return JEWELRY_JEWELRY___LEFT_HAND_GOLD_RINGS;
    } else if (assetNum == 11) {
      return JEWELRY_JEWELRY___LEFT_HAND_SILVER_RINGS;
    } else if (assetNum == 12) {
      return JEWELRY_JEWELRY___RED_BRACELET;
    } else if (assetNum == 13) {
      return JEWELRY_JEWELRY___RED_SPORTS_WATCH;
    } else if (assetNum == 14) {
      return JEWELRY_JEWELRY___SILVER_CHAIN_WITH_MEDALLION;
    } else if (assetNum == 15) {
      return JEWELRY_JEWELRY___SILVER_CHAIN_WITH_RED_RUBY;
    } else if (assetNum == 16) {
      return JEWELRY_JEWELRY___SILVER_CHAIN;
    } else if (assetNum == 17) {
      return JEWELRY_JEWELRY___SILVER_STUD_EARRINGS;
    }
    return JEWELRY_JEWELRY___BLUE_BRACELET;
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