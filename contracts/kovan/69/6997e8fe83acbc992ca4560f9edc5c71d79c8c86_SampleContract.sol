/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

contract SampleContract {
    int public x;

    function setX(int _x) public {
        x = _x;
    }
}