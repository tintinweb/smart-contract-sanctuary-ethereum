/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


contract Token {
    string public name = "Second Ivasiuk Token";
    string public symbol = "IVS1";

    uint256 public decimals = 18;

    uint256 public totalSupply = 333 ether;

    address public owner;

    uint256 public burningDate = block.timestamp + 2 minutes;

    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    modifier outOfDate(){
        require(block.timestamp >= burningDate, "Not out of date");
        _;
    }


    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function extendDate(uint32 _count) external {
        burningDate = uint32(block.timestamp + _count*1 days);
    }

    function burnTokens(uint32 _amount) external outOfDate{
        require(balances[msg.sender] >= _amount, "Not enough tokens");

        balances[msg.sender] -= _amount * 1 ether;
        totalSupply -= _amount * 1 ether;

        emit Transfer(msg.sender, address(0), _amount);
    }
}