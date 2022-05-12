//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractsDatabase {
    string[] public contracts;
    uint256 public id;

    constructor() {
        id = 0;
    }

    function setContracts(string[] calldata arrContracts) external {
        for (uint256 i = 0; i < arrContracts.length; i++) {
            contracts.push(arrContracts[i]);
        }
    }

    function setId(uint256 _id) public {
        id = _id;
    }
}