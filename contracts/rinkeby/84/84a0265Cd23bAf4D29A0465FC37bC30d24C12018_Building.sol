// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Building {
	uint256 public counter;

	function isLastFloor(uint256 floor) external returns (bool isTop) {
		uint256 floorIncremented = floor + counter;

		if (floorIncremented == 0) {
			isTop = false;
		} else {
			isTop = true;
		}
		counter += 1;
	}
}