// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SusuToken {
    // Token metadata
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    // Mapping of addresses to token balances
    mapping(address => uint256) public balanceOf;

    // Event for token transfers
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Initialize the contract with the token metadata
    constructor() {
        name = "SusuToken";
        symbol = "SST";
        decimals = 9;
        totalSupply = 1 ether;
        balanceOf[msg.sender] = totalSupply;
    }

    // Transfer tokens from one address to another
    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value && value > 0);
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
    }

    // Approve another address to transfer tokens on behalf of the msg.sender
    function approve(address spender, uint256 value) public {
        require(balanceOf[msg.sender] >= value && value > 0);
        require(spender != address(0));
        address owner = msg.sender;
        _approve(owner, spender, value);
    }

    // Transfer tokens from one address to another using an approved allowance
    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value && value > 0);
        require(_allowance[from][msg.sender] >= value);
        balanceOf[from] -= value;
        _allowance[from][msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    // Get the approved allowance for an address
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    mapping(address => mapping(address => uint256)) private _allowance;

    function _approve(address owner, address spender, uint256 value) internal {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    event Approval(address indexed owner, address indexed spender, uint256 value);
}