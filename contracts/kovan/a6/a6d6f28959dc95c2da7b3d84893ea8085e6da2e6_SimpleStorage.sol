/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function setStoredData(uint x) public {
        storedData = x;
    }

    function getStoredData() public view returns (uint) {
        return storedData;
    }
}