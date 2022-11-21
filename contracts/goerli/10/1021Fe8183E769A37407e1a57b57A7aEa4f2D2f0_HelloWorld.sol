/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract HelloWorld {
    uint public id;

    function setId(uint _id) public {
        id = _id;
    }

    function getId() public view returns (uint) {
        return id;
    }
}