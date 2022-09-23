/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
//20220923
pragma solidity 0.8.0;

contract FOOD {
    uint pizlike = 0;
    uint pizhate = 0;
    uint burglike = 0;
    uint burghate = 0;

    function pizl() public returns(uint) {
        pizlike = pizlike + 1;
        return pizlike;
    }

    function pizh() public returns(uint) {
        pizhate = pizhate + 1;
        return pizhate;
    }

    function burgl() public returns(uint) {
        burglike = burglike + 1;
        return burglike;
    }

    function burgh() public returns(uint) {
        burghate = burghate + 1;
        return burghate;
    }
}