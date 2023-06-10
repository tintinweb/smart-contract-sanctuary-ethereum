/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TokenSale {
    address public admin;
    IERC20 public token;
    uint256 public price;
    uint256 public totalTokens;
    uint256 public tokensSold;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 totalPrice);

    constructor(IERC20 _token, uint256 _price, uint256 _totalTokens) {
        admin = msg.sender;
        token = _token;
        price = _price;
        totalTokens = _totalTokens;
        tokensSold = 0;
    }

    function buyTokens(uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        require(tokensSold + amount <= totalTokens, "Not enough tokens available");

        uint256 totalPrice = amount * price;
        require(msg.value >= totalPrice, "Insufficient funds");

        require(token.transfer(msg.sender, amount), "Failed to transfer tokens");
        tokensSold += amount;

        if (msg.value > totalPrice) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }

        emit TokensPurchased(msg.sender, amount, totalPrice);
    }

    function withdrawFunds() external {
        require(msg.sender == admin, "Only admin can withdraw funds");
        payable(admin).transfer(address(this).balance);
    }

    function withdrawTokens() external {
        require(msg.sender == admin, "Only admin can withdraw tokens");
        uint256 remainingTokens = token.balanceOf(address(this));
        require(token.transfer(admin, remainingTokens), "Failed to transfer remaining tokens");
    }
}