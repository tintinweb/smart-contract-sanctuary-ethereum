/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleStorage {
    uint256 public number;

    struct Tree {
        uint256 branch;
        string name;
    }

    // Tree public tree = Tree({ branch: 10, name: "palm tree" });
    Tree[] public trees;

    function store(uint _number) external {
        number = _number;
    }

    function retrieve() view external returns (uint256) {
        return number;
    }

    function appendTree(string calldata _name, uint256 _branch) external returns (string calldata) {
        trees.push(Tree({name: _name, branch: _branch}));
        return _name;
    }

}