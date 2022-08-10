/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract SimpleMappingExample {
    mapping(uint => bool) public mappingName;

    function setValue(uint _index) public {
        mappingName[_index] = true;
    }
}