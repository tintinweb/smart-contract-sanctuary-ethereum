/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract gozilla { 

    string a = "one";
    uint b = 2;

    function one() public view returns(string memory) {
        return a;
    }

function two() public view returns(uint) {
        return b;
    }

}