/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
	uint256 storedData;

	function set(uint x) public {
		storedData = x;
	}

	function setPlus100(uint x) public {
		storedData = x + 100;
	}

	function get() public view returns (uint) {
		return storedData;
	}
}