/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

contract SimpleStorage {
    uint storedData = 0; // State variable
    // ...
    function getData() view external returns(uint) {
        return storedData;
    }

    function saveData(uint data) external payable {
        storedData = data;
    }

}