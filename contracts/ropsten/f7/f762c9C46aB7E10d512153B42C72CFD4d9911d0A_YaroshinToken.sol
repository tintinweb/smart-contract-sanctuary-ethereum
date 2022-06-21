/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract YaroshinToken {
    string public name;
    string public symbol;
    uint8  public  decimals;
    address owner;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed from, address indexed to, uint value);

    constructor() {
        owner = msg.sender;
        name = "YarOsha";
        symbol = "YRX";
        decimals = 2;
    }

    function mint(address to, uint256 value) external {
        require(msg.sender == owner, "ERC20: You are not owner");
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function balanceOf(address to) external view returns(uint256) {
        return balances[to];
    }

    function approve(address spender, uint256 value) external returns(bool) {
        allowed[spender][msg.sender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address from, address spender) public view returns(uint256) {
        return allowed[spender][from];
    }

    function transfer(address to, uint256 value) external returns(bool) {
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns(bool) {
        require(balances[from] >= value, "ERC20: not enough tokens");
        require(allowed[msg.sender][from] >= value, "ERC20: no permission to spend");
        balances[from] -= value;
        balances[to] += value;
        allowed[msg.sender][from] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[msg.sender][from]);
        return true;
    }
}