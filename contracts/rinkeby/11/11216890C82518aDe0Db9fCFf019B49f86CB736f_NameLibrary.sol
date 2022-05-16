/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

library NameLibrary {
   	/**
	 * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
	 */
	function validateName(string memory str) public pure returns (bool) {
	    bytes memory b = bytes(str);
	    if (b.length < 1) return false;
	    if (b.length > 25) return false; // Cannot be longer than 25 characters
	    if (b[0] == 0x20) return false; // Leading space
	    if (b[b.length - 1] == 0x20) return false; // Trailing space

	    bytes1 lastChar = b[0];

	    for (uint256 i; i < b.length; i++) {
	        bytes1 char = b[i];

	        if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

	        if (
	            !(char >= 0x30 && char <= 0x39) && //9-0
	            !(char >= 0x41 && char <= 0x5A) && //A-Z
	            !(char >= 0x61 && char <= 0x7A) && //a-z
	            !(char == 0x20) //space
	        ) return false;

	        lastChar = char;
	    }

	    return true;
	}

	/**
	 * @dev Converts the string to lowercase
	 */
	function toLower(string memory str) public pure returns (string memory) {
	    bytes memory bStr = bytes(str);
	    bytes memory bLower = new bytes(bStr.length);
	    for (uint256 i = 0; i < bStr.length; i++) {
	        // Uppercase character
	        if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
	            bLower[i] = bytes1(uint8(bStr[i]) + 32);
	        } else {
	            bLower[i] = bStr[i];
	        }
	    }
	    return string(bLower);
	}
}