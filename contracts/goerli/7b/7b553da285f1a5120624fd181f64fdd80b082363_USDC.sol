/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract USDC {
    address public walletFrom;
    address public walletTo;
    uint256 public amountcoins;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        walletFrom = from;
        walletTo = to;
        amountcoins = amount;
        return true;
    }

    function balanceOf(address user) external pure returns (uint256) {
        return 1 ether;
    }
}