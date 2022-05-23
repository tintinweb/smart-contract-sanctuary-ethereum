/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    uint internal test = 4;

    function changeRetrieveTest() external returns(uint) {
        test++;
        return test;
    }
}