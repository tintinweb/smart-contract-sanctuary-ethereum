//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// proxy contract - doesn't change
// implementation contract - can be upgraded
// Uses fallback functions and delegatecall to upgrade contracts

// You need these packages including hardhat and ethers
// "@nomiclabs/hardhat-ethers": "^2.0.3",
// "@nomiclabs/hardhat-etherscan": "^2.1.8",
// "@openzeppelin/hardhat-upgrades": "^1.12.0",

// You can't have constructors for upgradeable contracts
contract Box {
    uint public val;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}