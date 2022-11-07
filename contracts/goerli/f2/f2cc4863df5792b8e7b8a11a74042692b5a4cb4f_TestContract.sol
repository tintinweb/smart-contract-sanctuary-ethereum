/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract TestContract {
    uint256 public number;
    function store(uint256 num) public {
        number = num;
    }
    function getNumber() public view returns (uint256){
        return number;
    }
}