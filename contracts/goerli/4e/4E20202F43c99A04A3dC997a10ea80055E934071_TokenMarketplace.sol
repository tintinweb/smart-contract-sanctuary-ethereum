// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external returns (uint256);
}

contract TokenMarketplace {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    mapping(address => uint) public price;

    function buy(
        address tokenAddress,
        uint amount
    ) external payable returns (bool) {
        IERC20 token = IERC20(tokenAddress);
        require(isAvailable(tokenAddress), "No token available!");
        require(
            token.balanceOf(address(this)) >= amount,
            "Not enough token available!"
        );

        uint costs = price[tokenAddress] * amount;
        require(costs == msg.value, "You don't have enough ETH to pay!");
        bool success = token.transfer(msg.sender, amount);
        require(success, "The transaction failed!");
        return true;
    }

    function sell(
        address tokenAddress,
        uint amount
    ) external payable returns (bool) {
        IERC20 token = IERC20(tokenAddress);
        uint costs = price[tokenAddress] * amount;
        require(address(this).balance >= costs);
        uint allowance = token.allowance(msg.sender, address(this));
        require(
            allowance >= amount,
            "You don't have  enough allowance to sell these token!"
        );
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "The transaction failed");
        (bool s, ) = msg.sender.call{value: costs}("");
        require(s, "No ETH for you!");
        return true;
    }

    function setPrice(address tokenAddress, uint value) public onlyOwner {
        require(price[tokenAddress] == 0, "There is already a price!");
        price[tokenAddress] = value;
    }

    function changePrice(address tokenAddress, uint newPrice) public onlyOwner {
        require(price[tokenAddress] != 0, "Please add a price first!");
        price[tokenAddress] = newPrice;
    }

    function isAvailable(address tokenAddress) public view returns (bool) {
        IERC20 token = IERC20(tokenAddress);
        uint balance = token.balanceOf(address(this));
        if (balance == 0) {
            return false;
        }
        return true;
    }

    function getPrice(address tokenAddress) public view returns (uint) {
        uint number = price[tokenAddress];
        return number;
    }

    function getTotalPrice(
        address tokenAddress,
        uint amount
    ) public view returns (uint) {
        uint number = price[tokenAddress];
        uint totalPrice = number * amount;
        return totalPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }
}