/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

contract Game2 {
    uint8 y = 210;

    event Winner(address winner);

    function win(uint8 x) public {
        uint8 sum = x + y;
        require(sum == 10);
        emit Winner(msg.sender);
    }
}