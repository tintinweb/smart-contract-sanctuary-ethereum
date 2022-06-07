/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
// Solidity program to
// demonstrate the use
// of 'While loop'

pragma solidity >=0.7.0 <0.9.0;

// Creating a contract
contract Types {
	
	// Declaring a dynamic array
	uint[] data;
	
	// Declaring state variable
	uint8 j = 0;
	
	// Defining a function to
	// demonstrate While loop'
	function loop(
	) public returns(uint[] memory){
	while(j < 5) {
		j++;
		data.push(j);
	}
	return data;
	}
}