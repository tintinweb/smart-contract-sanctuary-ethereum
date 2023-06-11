/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "Multiplication overflow");
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;
        require(a == b * c + a % b, "Division overflow");
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction underflow");
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b, "Addition overflow");
        return c;
    }
}

contract XST {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    constructor() {
        uint256 initialSupply = 2000000;  // Example initial supply of 1,000,000 tokens
        string memory tokenName = "SilverToken";  // Example token name
        uint8 decimalUnits = 8;  // Example of 8 decimal units
        string memory tokenSymbol = "XST";  // Example token symbol

        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) public {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(balanceOf[to] + value >= balanceOf[to], "Overflow detected");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(value);
        balanceOf[to] = balanceOf[to].safeAdd(value);

        emit Transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(value > 0, "Invalid value");

        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(value > 0, "Invalid value");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(balanceOf[to] + value >= balanceOf[to], "Overflow detected");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");

        balanceOf[from] = balanceOf[from].safeSub(value);
        balanceOf[to] = balanceOf[to].safeAdd(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].safeSub(value);

        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(value > 0, "Invalid value");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(value);
        totalSupply = totalSupply.safeSub(value);

        emit Burn(msg.sender, value);
        return true;
    }

    function freeze(uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(value > 0, "Invalid value");

        balanceOf[msg.sender] = balanceOf[msg.sender].safeSub(value);
        freezeOf[msg.sender] = freezeOf[msg.sender].safeAdd(value);

        emit Freeze(msg.sender, value);
        return true;
    }

    function unfreeze(uint256 value) public returns (bool) {
        require(freezeOf[msg.sender] >= value, "Insufficient freeze balance");
        require(value > 0, "Invalid value");

        freezeOf[msg.sender] = freezeOf[msg.sender].safeSub(value);
        balanceOf[msg.sender] = balanceOf[msg.sender].safeAdd(value);

        emit Unfreeze(msg.sender, value);
        return true;
    }

    function withdrawEther(uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(owner).transfer(amount);
    }

    receive() external payable {}
}