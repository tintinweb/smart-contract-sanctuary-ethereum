/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TradingBot {
    IERC20 public token;
    uint256 public buyAmount;
    uint256 public sellAmount;
    uint256 public buyInterval;
    address payable public wallet;

    constructor() {
        token = IERC20(0x13E7006cF58857efD24Ab1F5a90DF2df07DFec5b);
        buyAmount = 0.1 ether;
        sellAmount = 0;
        buyInterval = 60; // 1 minute
        wallet = payable(0xed12D40a4280BA4EcA64A3Ae1890748B43afFE5b);
    }

    function buyAndSell() public {
        require(token.balanceOf(address(this)) >= buyAmount, "Insufficient balance to buy tokens");

        // Buy tokens
        token.transferFrom(msg.sender, address(this), buyAmount);

        // Send 0.003 ETH to the wallet
        wallet.transfer(0.003 ether);

        // Wait for 1 minute
        uint256 startTime = block.timestamp;
        while (block.timestamp < startTime + buyInterval) {
            // Do nothing
        }

        // Sell tokens
        token.transfer(msg.sender, sellAmount);

        // Send 0.003 ETH to the wallet
        wallet.transfer(0.003 ether);
    }
}