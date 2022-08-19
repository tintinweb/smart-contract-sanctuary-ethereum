/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

contract Test2 {
    event Log(uint indexed a, uint indexed b, uint indexed c, uint d);

    function emitLog(uint index) public {
        for (uint i = 0; i < index; i++) {
            emit Log(9, 9, 9, 9);
        }
    }
}