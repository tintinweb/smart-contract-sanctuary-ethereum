/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract TestMap {


    mapping(uint8 => string) indexToName;

    function setVal(uint8 id, string memory name) public {
        indexToName[id] = name;
    }

    function getVal(uint8 id) public view returns (string memory) {
        return indexToName[id];
    } 

}