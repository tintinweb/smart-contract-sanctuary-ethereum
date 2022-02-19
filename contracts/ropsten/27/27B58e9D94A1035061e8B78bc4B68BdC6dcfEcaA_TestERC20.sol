// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

contract TestERC20 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint8 public immutable decimals = 18;
    string public name;
    string public symbol;
    uint256 public immutable totalSupply = 1;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function approve(address spender, uint256 allowance_)
        external
        returns (bool)
    {
        allowance[msg.sender][spender] = allowance_;
        emit Approval(msg.sender, spender, allowance_);
        return true;
    }

    function transfer(address to, uint256 amount)
        external
        returns (bool)
    {
        transferFrom(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address owner, address to, uint256 amount)
        public
        returns (bool)
    {
        uint256 a = owner == msg.sender
            ? uint256(int256(-1))
            : allowance[owner][msg.sender];
        if (a != uint256(int256(-1))) {
            allowance[owner][msg.sender] = a - amount;
        }
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(owner, to, amount);
        return true;
    }

    function mint(uint256 amount)
        external
    {
        balanceOf[msg.sender] += amount;
    }
}