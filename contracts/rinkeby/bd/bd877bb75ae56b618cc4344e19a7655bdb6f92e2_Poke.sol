/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Poke {
    uint256 num = 0;
    function poke() public {
        num = num + 1;
        emit Poked(block.timestamp, num);
    }
    event Poked(uint256 currTime, uint256 currNum);
}