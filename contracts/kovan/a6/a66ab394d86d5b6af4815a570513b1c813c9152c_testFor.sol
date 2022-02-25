/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract testFor{
    uint public a;
    function test(uint b)public {
        a = b;
    }
    function test2(uint c) public view returns(uint) {
        return a;
    }
}