/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test2 {
    uint public x;

    event UpdateVariable(uint, uint, uint);

    function updateVariable(uint _x) external  {
        x = _x;

        emit UpdateVariable(_x, block.timestamp, block.number);
    }
}