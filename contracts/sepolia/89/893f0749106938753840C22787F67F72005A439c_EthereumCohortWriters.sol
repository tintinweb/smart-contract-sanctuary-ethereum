/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract EthereumCohortWriters {
    
    string[] ethereumWriters;

    function addNewWriter(string calldata writer) public {
        ethereumWriters.push(writer);
    }

    function getAllWriters() public view returns (string[] memory) {
        return ethereumWriters;
    }
}