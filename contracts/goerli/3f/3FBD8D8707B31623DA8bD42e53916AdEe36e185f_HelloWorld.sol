// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

contract HelloWorld {
	function greet(string calldata name) public pure returns (string memory) {
		return string.concat("Hello ", name, "!"); // string.concat() requires ^0.8.12
	}
}