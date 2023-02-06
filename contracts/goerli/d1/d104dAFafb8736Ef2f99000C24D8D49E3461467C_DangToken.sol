// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract DangToken{
    string public name='My Token';
    string public symbol='MTN';
    uint public totalSupply=1000000;
    address public owner;
    mapping(address=>uint) balances;

    constructor(){
        owner=msg.sender;
        balances[msg.sender]=totalSupply;
    }

    function transfer(address to,uint amount) external{
        balances[msg.sender] -=amount;
        balances[to] +=amount;
    }

    function balanceOf(address account) external view returns(uint){
        return balances[account];
    }

}