/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashLabs {
    string public name = "HashLabs";
    string public symbol = "Hash";
    uint256 public totalSupply = 1000000000 * 10**18;
    uint8 public decimals = 18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    bool public mintingEnabled = true;
    bool public blacklistingEnabled = true;
    bool public paused = false;

    address private owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    modifier notPaused() {
        require(!paused, "Token transfers are paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public notPaused returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        uint256 taxAmount = amount / 100;
        uint256 transferAmount = amount - taxAmount;

        balances[msg.sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;

        emit Transfer(msg.sender, recipient, transferAmount);
        emit Transfer(msg.sender, address(this), taxAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public notPaused returns (bool) {
        require(amount >= 0, "Amount must be non-negative");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public notPaused returns (bool) {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        uint256 taxAmount = amount / 100;
        uint256 transferAmount = amount - taxAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[address(this)] += taxAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, address(this), taxAmount);

        return true;
    }

    function mint(address recipient, uint256 amount) public onlyOwner {
        require(mintingEnabled, "Minting is not enabled");

        totalSupply += amount;
        balances[recipient] += amount;

        emit Transfer(address(0), recipient, amount);
    }

    function burn(uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function enableMinting() public onlyOwner {
        mintingEnabled = true;
    }

    function disableMinting() public onlyOwner {
        mintingEnabled = false;
    }
}