/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract S { 
    string[] array;

    function writeName(string memory a) public {
        array.push(a);
    }

    function getNuame(uint b) public view returns(string memory) {
        return array[b-1];
    }

}