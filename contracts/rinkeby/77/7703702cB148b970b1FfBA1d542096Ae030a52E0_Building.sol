pragma solidity ^0.8.0;

contract Building {
	
	uint iter;
	uint lastFloor;

	constructor(uint _lastFloor) public {
		iter = 1;
		lastFloor = _lastFloor;
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