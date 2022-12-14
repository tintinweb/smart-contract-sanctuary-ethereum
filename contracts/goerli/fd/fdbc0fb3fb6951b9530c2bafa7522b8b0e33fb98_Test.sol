/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    uint public x;

    event UpdateX(uint, uint, uint);

    function updateX(uint _x) external  {
        x = _x;

        emit UpdateX(_x, block.timestamp, block.number);
    }
}