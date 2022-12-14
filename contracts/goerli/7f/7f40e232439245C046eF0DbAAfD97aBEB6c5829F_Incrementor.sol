// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Incrementor {
	uint256 public _value;

	constructor() {
		_value = 0;
	}

	function increment() external {
		_value++;
	}
}