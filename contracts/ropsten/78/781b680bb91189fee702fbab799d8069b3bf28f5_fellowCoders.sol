/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// pragma version
pragma solidity ^0.5.12;

// Creating a contract
contract fellowCoders
{
	
	uint hashDigits = 8;
	
	// Equivalent to 10^8 = 8
	uint hashModulus = 10 ** hashDigits;

	// Function to generate the hash value
	function _generateRandom(string memory _str)
		public view returns (uint)
	{
		uint random =
			uint(keccak256(abi.encodePacked(_str)));
			
		// Returning the generated hash value
		return random % hashModulus;
	}

}