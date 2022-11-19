// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
interface Building {
  function isLastFloor(uint) external returns (bool);
}

interface IElevator {
    function top() external returns (bool);
}

contract Burj is Building {

    IElevator public constant elevator = IElevator(0x9f755007b95dB3027fce3574641706243aF85cFC);

    function isLastFloor(uint) external returns (bool) {
        return elevator.top();
    }
}