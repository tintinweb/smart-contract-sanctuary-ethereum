// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";

/// @title BLONKS Traits Contract
/// @author Matto
/// @notice This contract determines traits and builds the attribute list (JSON) for marketplaces.
/// @dev These functions had to be split due to the data types being returned (array and string).
/// @custom:security-contact [email protected]
contract BLONKStraits {
  using Strings for string;
	
  	function tr(string memory _k, string memory _v)
    	internal
    	pure
    	returns (string memory)
  	{
    	string memory str = string(abi.encodePacked('{"trait_type":"', _k, '","value":"', _v, '"},'));
    	return str;
  	}

	function calculateTraitsArray(uint256 eT)
		external
		view
		virtual
		returns (uint8[11] memory)
	{
		uint8[11] memory tA;
		uint256 test;

		tA[10] = 0;
		// "Background" (using baseFee entropy (that was appended to token entropy)) 
		test = eT % 100;
		if (test > 98) {
			tA[0] = 0; // RAINBOW!
		} else if (test > 50) {
			tA[0] = 1;// Gradient
		} else {
			if (test > 10) {
				tA[0] = 2; // Glow
			} else {
				tA[0] = 3; // Spotlight
			}
		}
		eT /= 100;
		
		// Eyes
		if (eT % 29 == 28) { 
			tA[1] = 1; // Degen
			tA[10]++;
		} else if (eT % 59 == 58){ 
			tA[1] = 2; // BULLISH
			tA[10]++;
		} else { 
			tA[1] = 0; // None
		}
		eT /= 100;

		// Teeth
		tA[2] = 0; // None
		if (eT % 6 == 0) {
			tA[10]++;
			eT /= 10;
			test = eT % 10;
			if (test > 4) {
				tA[2] = 1; // Full Grill
			} else if (test > 1) {
				tA[2] = 2; // Beaver Bucks
			} else {
				tA[2] = 3; // Tusks
			}
		} 
		eT /= 10;

		// Extra Detail
		tA[3] = 0; // None
		if (eT % 10 == 9) {
			tA[10]++;
			eT /= 10; 
			test = 1 + eT % 10;
			if (test > 5) { 
				tA[3] = 1; // Drool
			} else if (test > 3) { 
				tA[3] = 2; // Bloody Nose
			} else if (test > 1) { 
				tA[3] = 3; // Sweat Drop
			} else if (test == 1) { 
				tA[3] = 4; // Teardrop Tat
			}
		} 
		eT /= 10;

		// Eyewear
		tA[4] = 0; // None
		if (eT % 5 == 4) {
			tA[10]++;
			eT /= 10;
			test = eT % 10;
			if (test > 5) { 
				tA[4] = 1; // Trendy Glasses
			} else if (test > 2) {
				tA[4] = 2; // Pink Shades
			} else if (test > 0) { 
				tA[4] = 3; // 3D Glasses
			} else { 
				tA[4] = 4; // Poker-Champs
			}
		}
		eT /= 10;

		// Hair / Headband
		tA[5] = 0; // None (Hair)
		tA[6] = 0; // None (Headband
		test = eT % 10;
		eT /= 10;
		if (eT % 7 > 2) { // Hair
			tA[10]++;
			if (test > 7) {
				tA[5] = 1; //  Bandana
			} else if (test > 5) { 
				tA[5] = 2; //  Undercut
			} else if (test > 2) {
				tA[5] = 3; //  Long / Asymmetric
			} else { 
				tA[5] = 4; // Mohawk
			}
		}
		eT /= 10;
		if (eT % 10 > 7 && test <= 7) { // Headband
			tA[10]++;
			tA[6] = 1; // Gold
			eT /= 10;
			if (eT % 10 > 7) {
				tA[6] = 2; // Gold & Green
			}
		} 
		eT /= 10;

		// Lobe Piercings / Helix Piercings
		tA[7] = 0; // None (Lobe Piercings)
		tA[8] = 0; // None (Helix Piercings)
		if (eT % 5 == 0) {
			tA[10]++;   
			eT /= 10;
			test = eT % 3; // 0 Right, 1 Left, 2 Both
			eT /= 10;
			if (eT % 20 == 19) {
				tA[7] = 4; // Guages
			} else if (test == 0) { 
				tA[7] = 1; // Diamond Stud in Right Ear
			} else if (test == 1) {
				tA[7] = 2; // Diamond Stud in Left Ear
			} else if (test == 2) {
				tA[7] = 3; // Double Diamond Studs!
			}
			if (eT % 20 < 19) { // Helix piercing requires not Guages
				eT /= 10;
				test = eT % 7; // 0 Right, 1 Left, 2 Both, > 2 None
				if (test == 0) { 
					tA[8] = 1; // Gold Ring in Right Ear
				} else if (test == 1) {
					tA[8] = 2; // Gold Ring in Left Ear
				} else if (test == 2) {
					tA[8] = 3; // Double Gold Rings!
				}
			}
		}
		eT/= 10;

		// Other
		tA[9] = 0; // Comfy T-shirt
		if (eT % 3 == 2) {
			tA[10]++;
			test = eT % 10;
			eT /= 10;
			if (test > 6) {
				tA[9] = 1; // Beard
			} else if (test > 2) {
				if (test > 4) {
					tA[9] = 2; // Black Choker
				} else {
					tA[9] = 3; // Gold Choker
				}
			} else {
				if (eT % 4 < 3) {
					tA[9] = 4; // Black Turtleneck
				} else { 
					tA[9] = 5; // Gold & Green Sweater
				}
			}
		}
		return tA;
	}

  function calculateTraitsJSON(uint8[11] memory tA)
  	external
		view
		virtual
		returns (string memory)
	{
		string memory v = '';
		string memory t = '"attributes":[';
		if (tA[0] == 0) {
			v = 'RAINBOW!';
		} else if (tA[0] == 1) {
			v = 'Gradient';
		} else if (tA[0] == 2) {
			v = 'Glow';
		} else {
			v = 'Spotlight';
		}
		t = string(abi.encodePacked(t,tr("Background", v)));
		
		if (tA[1] == 1) {
			v = 'Degen';
		} else if (tA[1] == 2) {
			v = 'BULLISH';
		} else {
			v = 'None';
		}
		t = string(abi.encodePacked(t,tr("Eye Special", v)));

		if (tA[2] == 0) {
			v = 'None';
		} else if (tA[2] == 1) {
			v = 'Full Grill';
		} else if (tA[2] == 2) {
			v = 'Beaver Bucks';
		} else {
			v = 'Just Tusks';
		}
		t = string(abi.encodePacked(t,tr("Teeth Showing", v)));
	
		if (tA[3] == 0) {
			v = 'None';
		} else if (tA[3] == 1) {
			v = 'Drool';
		} else if (tA[3] == 2) {
			v = 'Bloody Nose';
		} else if (tA[3] == 3) {
			v = 'Sweat Drop';
		} else {
			v = 'Teardrop Tat';
		}
		t = string(abi.encodePacked(t,tr("Extra Detail", v)));

		if (tA[4] == 0) {
			v = 'None';
		} else if (tA[4] == 1) {
			v = 'Trendy Glasses';
		} else if (tA[4] == 2) {
			v = 'Pink Shades';
		} else if (tA[4] == 3) {
			v = '3D Glasses';
		} else {
			v = 'Poker-Champs';
		}
		t = string(abi.encodePacked(t,tr("Eyewear", v)));

		if (tA[5] == 0) {
			v = 'None';
		} else if (tA[5] == 1) {
			v = 'Bandana';
		} else if (tA[5] == 2) {
			v = 'Undercut';
		} else if (tA[5] == 3) {
			v = 'Long / Asymmetric';
		} else {
			v = 'Mohawk';
		}
		t = string(abi.encodePacked(t,tr("Hair/Bandana", v)));

		if (tA[6] == 0) {
			v = 'None';
		} else if (tA[6] == 1) {
			v = 'Gold';
		} else {
			v = 'Gold & Green';
		}
		t = string(abi.encodePacked(t,tr("Headband", v)));

		if (tA[7] == 0) {
			v = 'None';
		} else if (tA[7] == 1) {
			v = 'Diamond Stud in Right Ear';
		} else if (tA[7] == 2) {
			v = 'Diamond Stud in Left Ear';
		} else if (tA[7] == 3) {
			v = 'Double Diamond Studs!';
		} else {
			v = 'Guages';
		}
		t = string(abi.encodePacked(t,tr("Lobe Piercings",v)));

		if (tA[8] == 0) {
			v = 'None';
		} else if (tA[8] == 1) {
			v = 'Gold Ring in Right Ear';
		} else if (tA[8] == 2) {
			v = 'Gold Ring in Left Ear';
		} else {
			v = 'Double Gold Rings!';
		}
		t = string(abi.encodePacked(t,tr("Helix Piercings",v)));

		if (tA[9] == 0) {
			v = 'Comfy T-shirt';
		} else if (tA[9] == 1) {
			v = 'Beard';
		} else if (tA[9] == 2) {
			v = 'Black Choker';
		} else if (tA[9] == 3) {
			v = 'Gold Choker';
		} else if (tA[9] == 4) {
			v = 'Black Turtleneck';
		} else {
			v = 'Gold & Green Sweater';
		}
		t = string(abi.encodePacked(t,tr("Other",v)));

		if (tA[10] == 0) {
			v = 'Base';
		} else {
			v = 'Custom';
		}
		t = string(abi.encodePacked(t,'{"trait_type":"BLONK Type","value":"',v,'"}]'));
		return t;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}