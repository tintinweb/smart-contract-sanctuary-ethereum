// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Elevator {
	function goTo(uint256) external;
}

contract Building {
	uint256 public counter;

	address contractAddress;
	Elevator public elevator;

	constructor(address _contractAddress) payable {
		contractAddress = _contractAddress;
	}

	function isLastFloor(uint256 floor) external returns (bool isTop) {
		uint256 floorIncremented = floor + counter;

		if (floorIncremented == 0) {
			isTop = false;
		} else {
			isTop = true;
		}
		counter += 1;
	}

	function goToTop(uint256 floor) external {
		elevator = Elevator(contractAddress);
		elevator.goTo(floor);
	}
}