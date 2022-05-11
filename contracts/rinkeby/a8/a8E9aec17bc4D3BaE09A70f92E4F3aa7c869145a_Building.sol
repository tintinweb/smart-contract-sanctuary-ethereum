pragma solidity ^0.8.7;
import "./IElevator.sol";

contract Building {
    IElevator public elevator;
    uint256 count = 0;

    constructor(IElevator _elevator) {
        elevator = _elevator;
    }

    function isLastFloor(uint256 _floor) external view returns (bool) {
        if (count == 0) {
            count == _floor;
            return false;
        } else {
            return true;
        }
    }

    function callGoTo(uint256 _floor) public {
        elevator.goTo(_floor);
    }
}

pragma solidity ^0.8.7;

interface IElevator {
    function goTo(uint256 _floor) external;
}