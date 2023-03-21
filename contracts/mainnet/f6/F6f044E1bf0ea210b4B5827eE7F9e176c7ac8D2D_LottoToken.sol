/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// Contract LottoToken
// SPDX-License-Identifier: MIT



pragma solidity ^0.8.18;

contract LottoToken {
    // Declare public variables to store token name, symbol, decimals, and total supply
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Declare public variables to store the thresholds for burning and releasing tokens
    uint256 public BMThreshold;
    uint256 public BMAmount;

    // Declare public variable to store contract owner address
    address public owner;

    // Declare mappings to store balances and allowances for each address
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Declare events for token transfers, approvals, and burning/releasing tokens
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BMRelease(uint256 amount);
    event BMBurn(uint256 amount);

    // Constructor function to initialize token name, symbol, decimals, and total supply
    constructor() {
        name = "LottoToken";
        symbol = "LOTO";
        decimals = 18;
        totalSupply = 1000000000 * 10 ** uint256(decimals);

        // Set the thresholds for burning and releasing tokens
        BMThreshold = 990000000 * 10 ** uint256(decimals);
        BMAmount = 100000000 * 10 ** uint256(decimals);

        // Set the contract owner address and allocate total supply to the owner's balance
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    // Modifier function to restrict access to only the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    // Function to transfer tokens to a recipient address
    function transfer(address to, uint256 value) public returns (bool) {
        // Check if recipient address is valid and transfer amount is greater than zero
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Transfer amount must be greater than zero");

        // Check if sender has sufficient balance to transfer tokens
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        // Transfer tokens from sender to recipient address
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        // Emit transfer event
        emit Transfer(msg.sender, to, value);

        // Return true to indicate successful transfer
        return true;
    }

    // Function to approve another address to spend tokens on behalf of the sender
    function approve(address spender, uint256 value) public returns (bool) {
        // Check if spender address is valid and approval amount is greater than zero
        require(spender != address(0), "Invalid spender address");
        require(value > 0, "Approval amount must be greater than zero");

        // Set the allowance for spender address to spend tokens on behalf of the sender
        allowance[msg.sender][spender] = value;

        // Emit approval event
        emit Approval(msg.sender, spender, value);

        // Return true to indicate successful approval
        return true;
    }

    // Function to transfer tokens from a specific address to a recipient address
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        // Check if recipient address is valid and transfer amount is greater than zero
        require(to != address(0), "Invalid recipient address");
        require(value > 0, "Transfer amount must be greater than zero");

        // Check if sender has sufficient allowance to transfer tokens
        require(value <= allowance[from][msg.sender], "Insufficient allowance");

        // Check if sender has sufficient balance to transfer tokens
        require(balanceOf[from] >= value, "Insufficient balance");

        // Transfer tokens from sender to recipient address
        balanceOf[from] -= value;
        balanceOf[to] += value;

        // Deduct the transfer amount from the sender's allowance
        allowance[from][msg.sender] -= value;

        // Emit transfer event
        emit Transfer(from, to, value);

        // Return true to indicate successful transfer
        return true;
    }
}