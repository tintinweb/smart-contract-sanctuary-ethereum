// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract TOKEN {
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "TRE70LIN";
        symbol = "TRE70LIN";
        decimals = 18;
        totalSupply = 400000 * (uint256(10) ** decimals);

        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public payable returns (bool success) {

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return false;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        payable
        returns (bool success)
    {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}