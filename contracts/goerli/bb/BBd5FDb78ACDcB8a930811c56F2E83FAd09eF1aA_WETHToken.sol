/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WETHToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    bool public paused;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event Pause();
    event Unpause();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor() {
        name = "wETH Token";
        symbol = "wETH";
        decimals = 18;
        _totalSupply = 10000000000 * 10**uint(decimals); // 100 billion tokens, 18 decimal places
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        paused = false;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        allowances[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        require(balances[from] >= value, "Insufficient balance");
        require(allowances[from][msg.sender] >= value, "Insufficient allowance");

        balances[from] -= value;
        balances[to] += value;
        allowances[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    function burn(uint256 value) public onlyOwner whenNotPaused returns (bool) {
        require(balances[msg.sender] >= value, "Insufficient balance");

        balances[msg.sender] -= value;
        _totalSupply -= value;

        emit Burn(msg.sender, value);
        return true;
    }

    function pause() public onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpause();
    }

    function batchTransfer(address[] memory to, uint256[] memory value) public whenNotPaused returns (bool) {
        require(to.length == value.length, "Invalid input");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < to.length; i++) {
            totalAmount += value[i];
        }

        require(balances[msg.sender] >= totalAmount, "Insufficient balance");

        for (uint256 i = 0; i < to.length; i++) {
            balances[msg.sender] -= value[i];
            balances[to[i]] += value[i];
            emit Transfer(msg.sender, to[i], value[i]);
        }

        return true;
    }

    function lockTokens(address[] memory addresses) public view onlyOwner whenNotPaused returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Invalid address");

            // Add your lock logic here
            // Example: lockedAddresses[addresses[i]] = true;
        }

        return true;
    }

    function unlockTokens(address[] memory addresses) public view onlyOwner whenNotPaused returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Invalid address");

            // Add your unlock logic here
            // Example: lockedAddresses[addresses[i]] = false;
        }

        return true;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}