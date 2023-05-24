// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC20Balance is IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20Airdrop {

    event AirdropCreated(address indexed tokenAddress, address[] indexed recipients, uint256 amount);

    function createAirdrop(address tokenAddress, address[] memory recipients, uint256 amount) external {
        IERC20Balance token = IERC20Balance(tokenAddress);
        require(token.balanceOf(address(this)) >= recipients.length * amount, "Insufficient balance for airdrop");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amount), "Token transfer failed");
        }
        emit AirdropCreated(tokenAddress, recipients, amount);
    }

    function withdraw(address tokenAddress) external {
        IERC20Balance token = IERC20Balance(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}