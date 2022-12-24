/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ContractTest {
    string public name = "Julio";

    function setName(string memory _name) external {
        name = _name;
    }

    function getName() external view returns (string memory) {
        return name;
    }
}