/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract keyboards {
    string[] public createKeyboards;

    function getKeyboards() view public returns(string[] memory){
        return createKeyboards;
    }

    function create(string calldata _description) external {
    createKeyboards.push(_description);
  }
}