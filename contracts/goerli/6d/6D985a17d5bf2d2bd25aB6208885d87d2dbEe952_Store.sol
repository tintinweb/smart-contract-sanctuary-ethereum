// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

/**
* @title 
* @author Anthony (fps) https://github.com/0xfps.
* @dev 
*
*/
contract Store {
	mapping(address => uint8) public maps;
	
	function store(uint8 x) public {
		maps[msg.sender] = x;
	}
	
	function get() public view returns (uint8) {
		return maps[msg.sender];
	}
}