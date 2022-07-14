/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract A {

    function result() public pure returns(bool) {
        return false;
    }

    function getOne() public pure returns(bool) {
        bool r = result();
        return r;
    }
}