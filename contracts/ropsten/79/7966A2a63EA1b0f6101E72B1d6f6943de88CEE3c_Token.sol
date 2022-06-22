/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Token{
    string public name;
    string public symbol;
    uint8 public decimals;
    address owner;
    address staking;
    uint256 public totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address from, address to, uint256 value);
    event Approval(address from, address sender, uint256 value);

    modifier onlyOwner(){
        require(owner == msg.sender, "ERC20:You are not owner");
        _;
    }

    modifier enoughTokens(address from, uint256 value){
        require(balances[from] >= value, "ERC20: not enough tokens");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals){
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }


    function mint(address to, uint256 value) public{
        require(owner == msg.sender || staking == msg.sender, "ERC20:You are not owner");
        balances[to] += value;
        totalSupply += value;
        emit Transfer(address(0), to, value);
    }

    function approve(address spender, uint256 value) public returns(bool){
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address from, address spender) public view returns (uint256){
        return allowed[from][spender];
    }

    function transfer(address to, uint256 value) public enoughTokens(msg.sender, value) returns(bool){
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public enoughTokens(from, value) returns(bool){
        require(allowance(from, msg.sender) >= value, "ERC20: no permission to spend");
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    function balanceOf(address to) public view returns(uint){
        return balances[to];
    }

    function setStaking(address _staking) public onlyOwner{
        staking = _staking;
    }

}