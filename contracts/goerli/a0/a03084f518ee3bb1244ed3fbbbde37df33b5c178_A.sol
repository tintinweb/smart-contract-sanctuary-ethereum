/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.0;

contract A {
    uint public abc;
    function setABC() public {
        abc = 10;
    }
    function setABC2(uint _abc) public {
        abc = _abc;
    }
    function getABC() public view returns(uint) {
        return abc;
    }
}