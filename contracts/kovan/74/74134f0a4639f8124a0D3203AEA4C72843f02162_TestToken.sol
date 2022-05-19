/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

contract TestToken {
    mapping(address => uint) balances;

    function setBalanceOf(address account, uint balance) external {
        balances[account] = balance;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}