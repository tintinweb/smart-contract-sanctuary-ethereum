// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Jewelry {
  using Strings for uint256;
  string constant JEWELRY_JEWELRY___BLUE_BRACELET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAABQa//R3HrCAAAAAnRSTlMAGovxNEIAAAAmSURBVDjLY2AYBaOA9oCJgaEBvwBjA5MDqp6slWiGiIaMBuQgAwCMIQNE4xbxdAAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___BLUE_SPORTS_WATCH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAA+U8MAAAAujU4aAAAAAnRSTlMAGovxNEIAAAAnSURBVDjLY2AYBaOAWoAZjc+0Gk3gH4bASjSBsBVoAowho+E6eAEAaq0FVKUz0foAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAFVBMVEVHcEwAAAD3tnTx0YfXn2X////qxTeEfGjRAAAAAnRSTlMAGovxNEIAAAB9SURBVEjHY2AYBaNgFFAG2CBUAg0VMIKl2ARwOyIByRysQIzZ2NggEY8CRiMlJWU8NjAwKwGBAR4FQANCg5TxKlAlpCBUNcgZn4LQ0FAXvApUQ0PwK1AJdcGrQNjF1cXFEF9AmQANwBdQDMLGxoZ4kwyjoKDAaMYZBUMcAADcDhBiMV7rKgAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___DOUBLE_GOLD_CHAINS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAADqxTe8LtrhAAAAAnRSTlMAGovxNEIAAAA+SURBVDjLY2AYBUMJKDAwcKAIKDEwdKAISDYwpaAIcGStVEARYBMNmYAiwNjA5IBqTdZKNHtFQ0bDfhRgAgCIRwZLBDuNpwAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___DOUBLE_SILVER_CHAINS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAADOzs6k/6euAAAAAnRSTlMAGovxNEIAAAA+SURBVDjLY2AYBUMJKDAwcKAIKDEwdKAISDYwpaAIcGStVEARYBMNmYAiwNjA5IBqTdZKNHtFQ0bDfhRgAgCIRwZLBDuNpwAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN_WITH_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAADqxTe8LtrhAAAAAnRSTlMAGovxNEIAAABLSURBVDjLY2AYBUMJKDAwcOAXkGBgUEER4AArQgJsDAwTUAQYG5gcUK1J4ESzV0IFTYBtApoA1wI0Aa0VhASklhAylNFhNMoHNQAAZbIHLGDb+BQAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN_WITH_RED_RUBY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVHcEwAAADqxTeWLy/dkZE5yp0MAAAAAnRSTlMAGovxNEIAAABZSURBVEjHY2AYBaNgFFAGmCCUAvkKGMFSTAK47VBAMgcrEAIRingUgOzAZwPYCEW8HmVUwG8A0AhFAmGl4kQgLJ2NFfArMCaggFHZiFJHMgqMJupRMAoIAgDa8QPJfTN5mAAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAADqxTe8LtrhAAAAAnRSTlMAGovxNEIAAAA3SURBVDjLY2AYBUMJKDAwcOAXkGBgUEER4AArQgJsDAwTUAQYG5gcUK3JWolmr2jIaNiPAkwAAPPAA4rqRKA3AAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___GOLD_STUD_EARRINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEzqxTc1b1cjAAAAAXRSTlMAQObYZgAAABVJREFUKM9jYKAHYGJgcGAYBcMQAAB7tABDyjdolwAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_WATCH_ON_LEFT_WRIST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAADjwT4AAABf5/vhAAAAAnRSTlMAGovxNEIAAAAqSURBVDjLY2AYBaOATMCMLsB0AI2/Ck1gFYbASjQjwlagCTCGjAb04AUAd6wG7Nr6CEcAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___LEFT_HAND_GOLD_RINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEzqxTc1b1cjAAAAAXRSTlMAQObYZgAAABRJREFUKM9jYBgF9APMGCIJQ9xHAEy2AGSAi4gxAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___LEFT_HAND_SILVER_RINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEzOzs4tvipsAAAAAXRSTlMAQObYZgAAABRJREFUKM9jYBgF9APMGCIJQ9xHAEy2AGSAi4gxAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___RED_BRACELET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAAD/UFkA/4l6AAAAAnRSTlMAGovxNEIAAAAmSURBVDjLY2AYBaOA9oCJgaEBvwBjA5MDqp6slWiGiIaMBuQgAwCMIQNE4xbxdAAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___RED_SPORTS_WATCH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAADDPkUAAAAuER7GAAAAAnRSTlMAGovxNEIAAAAnSURBVDjLY2AYBaOAWoAZjc+0Gk3gH4bASjSBsBVoAowho+E6eAEAaq0FVKUz0foAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN_WITH_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAADOzs6k/6euAAAAAnRSTlMAGovxNEIAAABLSURBVDjLY2AYBUMJKDAwcOAXkGBgUEER4AArQgJsDAwTUAQYG5gcUK1J4ESzV0IFTYBtApoA1wI0Aa0VhASklhAylNFhNMoHNQAAZbIHLGDb+BQAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN_WITH_RED_RUBY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABABAMAAABYR2ztAAAAD1BMVEVHcEwAAADOzs6WLy/dkZFKWy3/AAAAAnRSTlMAGovxNEIAAABZSURBVEjHY2AYBaNgFFAGmCCUAvkKGMFSTAK47VBAMgcrEAIRingUgOzAZwPYCEW8HmVUwG8A0AhFAmGl4kQgLJ2NFfArMCaggFHZiFJHMgqMJupRMAoIAgDa8QPJfTN5mAAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEwAAADOzs6k/6euAAAAAnRSTlMAGovxNEIAAAA3SURBVDjLY2AYBUMJKDAwcOAXkGBgUEER4AArQgJsDAwTUAQYG5gcUK3JWolmr2jIaNiPAkwAAPPAA4rqRKA3AAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___SILVER_STUD_EARRINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEzOzs4tvipsAAAAAXRSTlMAQObYZgAAABVJREFUKM9jYKAHYGJgcGAYBcMQAAB7tABDyjdolwAAAABJRU5ErkJggg==";

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