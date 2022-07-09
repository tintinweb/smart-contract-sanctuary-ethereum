/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
contract Fruct_Token{
    uint256 public totalSupply;
    uint8 public immutable decimals;
    string public name;
    string public symbol;
    address public staking;
    address immutable owner;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    event Transfer(address indexed from, address indexed to , uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 balance);

    constructor(){
        totalSupply = 0;
        decimals = 1;
        name = "Fruct_Token";
        symbol = "FRCT";
        owner = msg.sender;
    }

    function mint(address to, uint256 value) external{
        require(owner == msg.sender || staking == msg.sender, "ERC20: You are not owner");
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function transfer(address to, uint256 value) external returns(bool){
        require(balances[msg.sender] >= value, "ERC20: not enough tokens");
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)external returns(bool){
        require(allowed[from][msg.sender] >= value, "ERC20: no permission to spend");
        require(balances[from] >= value, "ERC20: not enough tokens");
        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }


    function approve(address spender, uint256 value)external returns(bool){
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function setStaking(address _staking)external{
        staking = _staking;
    }

    function balanceOf(address to) external view returns(uint256){
        return balances[to];
    }

    function allowance(address from, address spender)external view returns (uint256){
        return allowed[from][spender];
    }

}