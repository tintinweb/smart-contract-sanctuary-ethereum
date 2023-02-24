/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract State{
	event StateChanged(address indexed author, string oldState, string newState);
	
	string _state = "init";

	function setState(string memory value) public {
		emit StateChanged(msg.sender, _state, value);
		_state = value;
	}

	function getState() public view returns (string memory) {
		return _state;
	}

}