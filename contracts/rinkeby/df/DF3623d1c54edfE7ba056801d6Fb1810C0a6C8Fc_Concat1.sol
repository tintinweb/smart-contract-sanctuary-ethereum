// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


contract Concat1 {
	string public str = "1";

	function concat(string calldata s) external {
		str = string.concat(str, s);
	}
}

contract Concat2 {
	string public str = "1";

	function concat(string calldata s) external {
		bytes memory b = abi.encodePacked(str, s);
		str = string(b);
	}
}