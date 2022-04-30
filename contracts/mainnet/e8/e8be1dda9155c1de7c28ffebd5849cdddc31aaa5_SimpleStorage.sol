/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleStorage {
    uint public storedData;

    function set(uint _storedData) public {
        storedData = _storedData;
    }
}