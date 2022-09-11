/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Keyboards {
    string[] public createdKeyboards;

    function getKeyboards() view public returns(string[] memory) {
        return createdKeyboards;
    }

    function create(string calldata _description) external {
        createdKeyboards.push(_description);
    }
}