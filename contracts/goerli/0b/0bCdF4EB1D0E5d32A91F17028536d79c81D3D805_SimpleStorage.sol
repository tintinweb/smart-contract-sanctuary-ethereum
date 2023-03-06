// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleStorage{
	uint public value;

	function updateValue(uint newValue) public {
		value = newValue;
	}
}