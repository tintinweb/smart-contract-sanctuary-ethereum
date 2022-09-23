/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.7.0 < 0.9.0;
/**
* @title Storage
* @dev store or retrieve variable value
*/


contract Storage {

	uint256 value;

	function addup(string memory name,uint8 number) public pure returns (uint8,string memory){
		return (number+1, string(string.concat(bytes(name),bytes("_taubyte"))));
	}

	function noparamsnoout()public{

	}

	function store(uint256 number) public{
		value = number;
	}

	function retrieve() public view returns (uint256){
		return value;
	}
}