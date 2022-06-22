/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;


contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    address private owner;
    address public staking;
    uint256 public totalSupply = 0;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address from, address to, uint value);

    event Approval(address from, address spender, uint value);

    modifier isOwner() {
        require(msg.sender == owner, "ERC20: You are not owner");
        _;
    }

    modifier isStak() {
        require(msg.sender == owner || msg.sender == staking, "ERC20: You are not owner");
        _;
    }

    modifier isPossible(address sender, uint value) {
        require(balances[sender] >= value, "ERC20: You don't have enough tokens");
        _;
    }

    modifier isAllowed(address from, uint value) {
        require(allowance(from, msg.sender) >= value || msg.sender == from , "ERC20: No permission to spend");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender; 
    }

    function mint(address to, uint value) public isStak {
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function setStaking(address _staking) public isOwner {
        staking = _staking;
    }

    function transfer(address to, uint value) public isPossible(msg.sender, value) returns(bool) {
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public isPossible(from, value) isAllowed(from, value) returns(bool) {
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 value) public returns(bool) {
        allowed[spender][msg.sender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address spender, address from) public view returns(uint) {
        return allowed[spender][from];
    }

    function balanceOf(address to) public view returns(uint) {
        return balances[to];
    }
}