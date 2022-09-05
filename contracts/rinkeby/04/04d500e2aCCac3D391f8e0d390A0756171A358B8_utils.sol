// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";

contract utils {

    string internal _seed_phrase = "DEVS";

    constructor() {}

    function _random(bytes memory input) internal pure returns (uint256) {return uint256(keccak256(input));}

    function _get_rand_in_range(uint256 rand, uint256 min, uint256 range) internal pure returns (uint256) {
        // Given a random uint256, get the number that is less than "range" integers larger than "min"
        return ((rand % range) + min);
    }

    function get_rand_in_range_toStr(uint256 rand, uint256 min, uint256 range) external pure returns (string memory) {
        return Strings.toString(_get_rand_in_range(rand, min, range));
    }

    function random(bytes memory input) external pure returns (uint256) {return _random(input);}

    function get_seed_phrase() external view returns (string memory) {return _seed_phrase;}

    function get_blur_data(bool blur) pure external returns (string[2] memory) {
        return (blur == true) ? ['displacementFilter_blur', '\n<feGaussianBlur in="SourceGraphic" stdDeviation="2"/>'] : ['displacementFilter', ''];
    }

    function add_trait(bytes memory json, string memory trait_type, string memory trait_value) external pure returns (bytes memory) {
        return abi.encodePacked(json, '{"trait_type": "', trait_type, '", "value": "', trait_value, '"}, ');
    }

    function get_cell_path(uint256 tokenId, uint64 _type) view external returns (bytes memory) {
        if (_type == 1) {
            return _get_epi_path();
        } else if (_type == 2) {
            return _get_muscle_path();
        } else if (_type == 3) {
            return _get_nerve_path(tokenId);
        } else {
            return _get_unspec_cell_body();
        }
    }

    function _add_path_point(string memory prefix, uint256 tokenId, string memory points) view internal returns (string memory) {
        // Once in a while, skip a point on the neuron
        // Make it a little more wacky and fun ya know
        return (_random(abi.encodePacked(prefix, tokenId, "ADD PATH POINT", _seed_phrase)) % 10 == 8) ? '' : points;
    }
    
    function _get_unspec_cell_body() pure internal returns (bytes memory) {
        return abi.encodePacked('\n<ellipse style="fill: url(#radial_grad); filter: url(#displacementFilter);" cx="175" cy="175" rx="200" ry="200"/>');
    }
    
    function _get_nerve_path(uint256 tokenId) view internal returns (bytes memory) {
        return abi.encodePacked(
            '\n<path d="M -4 155 ', 
            _add_path_point("FIRST NERVE POINT", tokenId, 'C 66 272 -5 355 4 348 '), 
            _add_path_point("SECOND NERVE POINT", tokenId, 'C 14 340 105 244 187 241 '), 
            _add_path_point("THIRD NERVE POINT", tokenId, 'C 269 238 341 329 346 334 '), 
            _add_path_point("FOURTH NERVE POINT", tokenId, 'C 351 338 288 256 284 176 '), 
            _add_path_point("FIFTH NERVE POINT", tokenId, 'C 280 96 335 17 328 18 '), 
            _add_path_point("SIXTH NERVE POINT", tokenId, 'C 321 18 253 98 195 94 '), 
            _add_path_point("SEVNTH NERVE POINT", tokenId, 'C 136 91 87 5 76 -0 '), 
            _add_path_point("EGITH NERVE POINT", tokenId, 'C 66 -6 94 66 76 105 '), 
            'C 58 143 -6 147 -4 155', 
            '"/>'
        );
    }
    
    function _get_epi_path() pure internal returns (bytes memory) {
        return abi.encodePacked('\n<path d="M 190 28 C 210 28 250 28 271 75 C 293 123 295 218 276 265 C 256 312 215 312 173 311 C 41 215 41 122 62 75 C 83 28 127 28 148 28 C 170 28 170 28 170 28 C 170 28 170 28 190 28"/>');
    }

    function _get_muscle_path() pure internal returns (bytes memory) {
        return abi.encodePacked('\n<path d="M 320 175 C 320 180 250 215 175 215 C 100 215 30 178.049 30 175 C 30 170 100 135 175 135 C 250 135 320 170 320 175 Z"/>');
    }

    function add_stop(string memory offset, string memory rgbs, bool open) external pure returns (bytes memory) {
        return abi.encodePacked('\n<stop offset="', offset, '" style="stop-color: rgb(', rgbs, (open == true) ? ');">' : ');"/>');
    }



    function breedEukaryotes(uint256 tokenId1, uint256 tokenId2, uint64 tokenGen1, uint64 tokenGen2) external view returns (uint256, uint256, uint256) {
        uint256 rand = _random(abi.encodePacked(tokenGen1, tokenGen2, "BREED EUKARYOTE CELLS", tokenId1, tokenId2, _seed_phrase)) % 100;
        if (rand < 20) {
            rand = _random(abi.encodePacked("CELL DAEATH", _seed_phrase, tokenId1, tokenId2)) % 2;
            if (rand == 0) {
                // cell 1 dies
                return (1, 0, 0);
            } else {
                // cell 2 dies
                return (2, 0, 0);
            }
        // birth 
        } else if (rand > 78) {
            // Inherit a parent's type 
            if (rand < 83) {
                return (0, 1, 1);
            } else if (rand < 88) {
                return (0, 2, 1);
            } else if (rand < 92) {
                return (0, 1, 2);
            } else {
                return (0, 2, 2);
            }
        // safe failure - no baby but no death
        } else {
            return (0, 0, 0);
        }
    }



    function breedProkaryote(uint256 tokenId, uint64 tokenGen) external view returns (uint256) {
        uint256 rand = _random(abi.encodePacked(tokenGen, "BREED CELLS", _seed_phrase, tokenId)) % 100;
        uint256 deathreshold = 10 - ((8 * ((tokenGen > 50 ? 50 :  tokenGen))) / 50);

        // Prokaryote mutates to eukaryote
        if ((rand == 42) || (rand == 69)) {
            return 2;
        // death
        } else if (rand < deathreshold) {
            return 1;
        } else {
            return 0;
        }
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