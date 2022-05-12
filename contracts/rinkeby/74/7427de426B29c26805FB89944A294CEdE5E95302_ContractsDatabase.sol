//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractsDatabase {
    string[] public contracts;

    function setContractsPush(string[] calldata arrContracts) external {
        for (uint256 i = 0; i < arrContracts.length; i++) {
            contracts.push(arrContracts[i]);
        }
    }

    function setContractsPop() public {
        contracts.pop();
    }
}