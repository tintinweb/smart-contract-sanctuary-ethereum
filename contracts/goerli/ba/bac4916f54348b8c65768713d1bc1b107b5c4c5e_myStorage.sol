/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract myStorage {
    string[] public capital = ["Bangkok", "London"];

    function capitalMemory() public {
        string[] memory newArr = capital;
        newArr[0] = "Rayong";
    }

    function capitalStorage() public {
        string[] storage newArr = capital;
        newArr[0] = "Rayong";
    }
}