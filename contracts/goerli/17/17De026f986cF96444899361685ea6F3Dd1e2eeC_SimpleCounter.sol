/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.26; // solhint-disable-line

contract SimpleCounter {

	uint256 public totalCalls;
	mapping(address => uint256) public counters;

	function inc() public {
		totalCalls++;
		counters[msg.sender]++;
	}

	function getCounter(address addr) public view returns (uint256) {
		return counters[addr];
	}

}