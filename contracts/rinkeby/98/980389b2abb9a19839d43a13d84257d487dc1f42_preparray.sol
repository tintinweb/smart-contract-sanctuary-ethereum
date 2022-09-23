/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract preparray {
    uint a;
    string[] array;

    function pushString(string memory items) public{
        array.push(items);
    }

    function lengArray() public view returns(uint) {
        return array.length;
    }
    function getString(uint n) public view returns(string memory) {
        return array[n-1];
    }
}