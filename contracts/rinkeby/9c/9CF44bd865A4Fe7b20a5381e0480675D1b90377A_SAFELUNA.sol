// SPDX-License-Identifier: GPL-3.0;

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract SAFELUNA {
    uint256 public totalSupply = 50000000;

    mapping(address => uint256) balance;
    mapping(address => uint256) totaltransfers;

    function transfer(
        address from,
        address to,
        uint amount
    ) external {
        balance[from] = balance[from] - amount;
        balance[to] = balance[to] + amount;

        // sum total of transfers made
    }

    function mint(address account, uint amount) external {
        totalSupply = totalSupply - amount;
        balance[account] = balance[account] + amount;
    }

    function checkbalance(address account) external view returns (uint) {
        return balance[account];
    }
}