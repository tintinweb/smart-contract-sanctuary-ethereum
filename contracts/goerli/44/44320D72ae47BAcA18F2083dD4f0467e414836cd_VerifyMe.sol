/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

contract VerifyMe {
    address public deployer;
    address private _one;
    uint256 private _two;

    constructor(address one, uint256 two) {
        deployer = msg.sender;
        _one = one;
        _two = two;
    }

    function getDeployer() external view returns (address) {
        return deployer;
    }
}