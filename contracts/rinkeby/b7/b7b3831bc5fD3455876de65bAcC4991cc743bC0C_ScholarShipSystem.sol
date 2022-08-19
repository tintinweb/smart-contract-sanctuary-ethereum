// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ScholarShipSystem {

	uint256 private number = 10;

	function getNumber() public view returns (uint256){
		return number;
	}

}