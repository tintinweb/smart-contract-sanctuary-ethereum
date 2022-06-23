/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

//Эта строка необходима для правильной работы с JSON!

//SPDX-License-Identifier: GPL-3.0

//Устанавливаем версии компилятора
pragma solidity 0.8.7;

// Создаём смарт-контракт
contract tokenA{

    address public owner;
    string public name;
    string public symbol;
    uint8  public  decimals;
    uint256 public   totalSupply;
    address public staking;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint256)) allowed;


    event Transfer(address from, address to, uint howtokens);
    event Approval(address from, address to, uint howtokens);

    constructor() 
    {
        owner = msg.sender;
        name = "tokenA";
        symbol = "tA";
        decimals = 9;
    }

    function setStaking(address _staking) public
    {
        require (msg.sender == owner, "ERC20: You are not owner");
        staking = _staking;
    }

    function mint(address to, uint256 value) public
    {
        require(msg.sender == owner || msg.sender == staking,"ERC20: You are not owner");
        totalSupply+=value;
        balances[to] += value;
        emit Transfer(address(0),to,value);
    }

    function balanceOf(address to) public view returns (uint)
    {
        return balances[to];
    }

    function transfer(address payable to, uint256 value) public returns(bool) 
    {
        require(balances[msg.sender] >= value,"ERC20: not enough tokens");
        balances[to] +=value;
        balances[msg.sender] -=value;
        emit Transfer(msg.sender,to,value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool) 
    {
        require(balances[from] >= value,"ERC20: not enough tokens");
       require(allowed[from][msg.sender]>=value, "ERC20: no permission to spend");
        balances[to] +=value;
        balances[from] -=value;
        allowed[from][msg.sender] -=value;
        emit Transfer(from,to,value);
        emit Approval(from,to,allowed[from][msg.sender]);
        return true;
    }

    function approve(address spender, uint256 value) public returns(bool) 
    {
        allowed[msg.sender][spender] = value;
        return true;
    }

    function allowance(address from, address spender) public view returns (uint256)
    {
        return allowed[from][spender];
    }
}