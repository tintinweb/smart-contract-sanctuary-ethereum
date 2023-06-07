// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./MyToken.sol";

contract TokenSale {
    MyToken public token;
    uint256 public rate = 0.01 ether; // 1 token = 0.01 ETH
    uint256 public saleEndTime;

    mapping(address => uint256) public tokenBalance;

    event TokensPurchased(address indexed buyer, uint256 amount);

    constructor(address _tokenAddress) {
        token = MyToken(_tokenAddress);
        saleEndTime = block.timestamp + 365 days; // Release tokens after 365 days of purchase
    }

    function buyTokens() external payable {
        require(block.timestamp < saleEndTime, "Token sale has ended");
        uint256 amount = msg.value / rate;

        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");

        tokenBalance[msg.sender] += amount;
        token.transfer(msg.sender, amount);

        emit TokensPurchased(msg.sender, amount);
    }

    function withdrawTokens() external {
        require(block.timestamp >= saleEndTime, "Tokens cannot be withdrawn yet");

        uint256 amount = tokenBalance[msg.sender];
        require(amount > 0, "No tokens to withdraw");

        tokenBalance[msg.sender] = 0;
        token.transfer(msg.sender, amount);
    }

    function withdrawETH() external {
        require(block.timestamp >= saleEndTime, "ETH cannot be withdrawn yet");

        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");

        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract MyToken {
    string public name = "My Token";
    string public symbol = "MTK";
    uint256 public totalSupply = 21_000_000 * 10**18; // 21 million tokens with 18 decimal places

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }
}