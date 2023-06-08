/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract PaymentContract {
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    function depositETH() external payable {
        // Logic to handle ETH deposit
        // Transfer the received ETH to the admin address
        payable(admin).transfer(msg.value);
    }

    function depositERC20(address tokenAddress, uint256 amount) external {
        // Logic to handle ERC20 deposit
        // Transfer the ERC20 tokens from the sender to the admin address
        IERC20 token = IERC20(tokenAddress);
         // Check the balance of the user
        require(token.balanceOf(msg.sender) >= amount, "Insufficient balance");
        token.transferFrom(msg.sender, admin, amount);
    }

    function getBalance() external view returns (uint256) {
        // Return the contract's ETH balance
        return address(this).balance;
    }
}