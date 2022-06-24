/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Implementation  {
    uint256 constant y = 6;
    uint256 public immutable z;
    uint256 public x;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        z = 8;
    }

    function initialize() public {
        x = 5;
    }

    function getY() public pure returns (uint256) {
        return y;
    }
}