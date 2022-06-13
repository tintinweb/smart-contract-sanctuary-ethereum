// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Timestamp {

	function timestamp() external view returns(uint) {
		return block.timestamp;
	}
}