// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract CallTestContract {
    uint public number;
    event Counter(uint time, uint countedNumber);

    function counter() external {
        number += 1;
        emit Counter(block.timestamp, number);
    }
}