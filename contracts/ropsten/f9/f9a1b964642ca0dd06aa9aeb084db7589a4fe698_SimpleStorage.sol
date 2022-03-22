/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleStorage {
    uint storedData = 5; 

    function getData() public view returns(uint) {
        return storedData;
    }

    function updateData(uint _data) public {
        storedData = _data;
    }
}